# System setup — Lenovo Legion S7 16IAH7 / Ubuntu (GNOME)

The steps that **can't be symlinked** — disk encryption, YubiKey login, and the
hardware/app quirks. `bootstrap.sh` handles the apt packages and dotfiles; this
doc is everything that touches `/etc`, needs a physical touch, or needs a secret
you type yourself. Do these after `bootstrap.sh`.

> Secrets are never stored here. SSH/GPG keys live in **1Password**; YubiKeys
> and the TPM must be **re-enrolled** on a fresh install — they are per-machine.

---

## 0. Machine facts

- **Hardware:** i7-12700H (20 threads), 22 GB RAM, 935 GB NVMe (WD SN810),
  NVIDIA RTX 3060 Mobile + Intel Iris Xe, WiFi 6E AX1690i, GNOME/Wayland.
- **OS:** Ubuntu (Resolute era), kernel 7.x-generic. **Boot uses `dracut`**
  (not initramfs-tools) + GRUB/shim; boot initrd is `/boot/initrd.img-<ver>`.
  Rebuild one kernel with `sudo dracut --force /boot/initrd.img-<ver> <ver>`
  (`--regenerate-all` can trip over phantom leftover kernel versions).
- **NVIDIA:** `sudo ubuntu-drivers install` (last pinned `nvidia-driver-595-open`),
  Prime **on-demand**, MOK-signed so it loads under Secure Boot.
- **Webcam:** Chicony **USB (uvcvideo)**, not the IPU6 MIPI sensor — only
  enumerates when the **physical privacy switch is ON**. No IPU6 driver needed.
- **Battery:** conservation mode ON (`/sys/bus/platform/devices/VPC2004:00/conservation_mode`)
  caps charge at ~85% (shown as 100%). Not wear — toggle off for true 100%.
- Secure Boot **enabled**; Windows wiped (full-disk LUKS).

---

## 1. Running sudo from a no-tty shell (Claude Code / scripts)

The sandboxed shell has **no tty**, so plain `sudo` fails with "a terminal is
required". Use a zenity askpass helper (GNOME/Wayland has `zenity`):

```bash
printf '#!/bin/bash\nzenity --password --title="sudo — Claude Code" 2>/dev/null\n' > /tmp/askpass.sh
chmod +x /tmp/askpass.sh
export SUDO_ASKPASS=/tmp/askpass.sh
sudo -A <command>          # graphical password dialog pops up; creds cache a while
```

For commands that read a **user secret** (LUKS passphrase, new TPM PIN), run them
in your **own terminal** — never route secrets through a shell you don't control.

---

## 2. LUKS full-disk encryption + TPM2 auto-unlock

Layout: root is **LUKS2 on `/dev/nvme0n1p3`** → LVM → ext4
(`ubuntu--vg-ubuntu--lv`); separate unencrypted `/boot` (`nvme0n1p2`).
LUKS UUID `520547cb-8824-4086-b6be-de705b75622b` (will differ on reinstall).

The Ubuntu installer's "hardware-backed"/TPM FDE option **fails** on this laptop
(Intel Boot Guard is fused by Lenovo; the installer precheck rejects it). So:
**install with a normal LUKS passphrase, then add TPM2 unlock in-place.**

```bash
# 1. tpm2-tools MUST be installed first — dracut's tpm2-tss module needs the
#    `tpm2` binary, or systemd-cryptsetup gets dropped from the initrd.
sudo apt install tpm2-tools cryptsetup

# 2. Enroll the TPM into a LUKS keyslot (run in YOUR terminal — asks for the
#    existing passphrase). PCR 7 = Secure Boot state.
#    With a PIN:
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/nvme0n1p3
#    Without a PIN (current choice — boots straight to login, disk decrypted):
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3

# 3. Tell crypttab to use the TPM:
sudo cp /etc/crypttab /etc/crypttab.pre-tpm.bak
# edit the root line's options to:  luks,tpm2-device=auto
#   dm_crypt-0 UUID=<uuid> none luks,tpm2-device=auto

# 4. Rebuild the initrd for the running kernel:
sudo dracut --force /boot/initrd.img-"$(uname -r)" "$(uname -r)"
```

**Keyslots end up:** 0 = passphrase (fallback, **keep forever**), 1 = tpm2.
On wrong PIN or a PCR-7 change (firmware/Secure Boot update) it **falls back to
the passphrase — no lockout**.

⚠️ **Any firmware / Secure Boot update that changes PCR 7 breaks the TPM seal.**
The next boot falls back to the passphrase ("TPM policy does not match current
system state"). Re-bind with `remove-luks-pin.sh` (wipe tpm2 slot + re-enroll):

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p3
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3
```

**Revert entirely:** restore `crypttab.pre-tpm.bak`, rebuild initrd, optionally
`systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p3`.

Also run `sudo fwupdmgr update` on a fresh install to apply UEFI db/dbx updates
**before** sealing the TPM (so you seal to the final PCR 7).

---

## 3. YubiKey — FIDO2 tap-to-sudo and tap-to-login

Two keys: **primary** = Security Key C NFC (FIDO2/U2F only, has a FIDO2 PIN);
**backup** = YubiKey 5C. Tooling (via `bootstrap.sh`): `libpam-u2f`,
`yubikey-manager`, `pcscd`, `pamtester`.

### 3a. Enroll both keys (needs each key physically present + PIN + touch)

`pamu2fcfg` needs a tty and a touch — run in **your own terminal**, one key per file:

```bash
mkdir -p ~/.config/Yubico
pamu2fcfg -n > /tmp/key1     # insert primary, type PIN, touch
pamu2fcfg -n > /tmp/key2     # insert backup,  type PIN, touch
# Merge onto ONE line: username first, then each -n entry (each already starts with ':')
printf 'numan%s%s\n' "$(cat /tmp/key1)" "$(cat /tmp/key2)" > ~/.config/Yubico/u2f_keys
chmod 600 ~/.config/Yubico/u2f_keys
rm /tmp/key1 /tmp/key2
```

Credentials are **touch-only** (no PIN at auth time → fast taps); the FIDO2 PIN
is only needed during enrollment. Do **not** `pamu2fcfg >> file` for the 2nd key
— that makes a broken second line.

### 3b. Wire into PAM (`sufficient` = lockout-safe: no key → falls back to password)

```bash
# sudo
sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.pre-u2f.bak
# GDM login + lock screen (same stack)
sudo cp /etc/pam.d/gdm-password /etc/pam.d/gdm-password.pre-u2f.bak
```

Add this line **before** `@include common-auth` in **both**
`/etc/pam.d/sudo` and `/etc/pam.d/gdm-password`:

```
auth       sufficient      pam_u2f.so openasuser cue
```

**Validate without logging out:** `pamtester gdm-password numan authenticate`
(tap → "successfully authenticated"). For sudo:
`unset SUDO_ASKPASS; sudo -k; sudo id` and tap.

- **Caveat:** tap-only login does **not** unlock the GNOME login keyring (needs
  the password) — an app may prompt for the keyring. Low impact (secrets in 1Password).
- **Recovery if the greeter breaks:** VT `Ctrl+Alt+F3` uses `/etc/pam.d/login`
  (untouched) → log in with password → restore the `.pre-u2f.bak` file.
- **1Password FIDO2:** register both keys as security keys (two-factor) in the
  1Password web UI — done in-app, nothing on disk.

---

## 4. 1Password, Firefox, git signing (manual, post-bootstrap)

`bootstrap.sh` installs the packages; these steps need you to sign in / touch UI:

1. **1Password app:** sign in → enable **Settings → Developer → SSH agent** and
   **"Use the SSH agent"**, and **"Integrate with 1Password CLI"**. The dotfiles
   ship `~/.ssh/config` (`IdentityAgent ~/.1password/agent.sock`) and
   `~/.config/1Password/ssh/agent.toml` (exposes vaults Private/Work/Development
   — the GitHub signing + auth keys live in Work/Development).
2. **Firefox 1Password extension:** install from addons.mozilla.org and approve
   the desktop-app connection (native-messaging). This is why we use the Mozilla
   **.deb**, not the snap — the snap is sandboxed and can't reach the app.
3. **git commit signing** is already configured (`~/.gitconfig` → `op-ssh-sign`,
   `commit.gpgsign=true`). Verify: make a commit, then
   `git log --show-signature` → "Good git signature".
4. **`gh auth login`** (HTTPS, token in keyring) — powers the git credential helper.
5. **CSC SSH** (`lumi`/`puhti`/`roihu`): needs `~/.ssh/csc.pub` / `csc-cert.pub`
   — export from 1Password or MyCSC on first connect (`IdentitiesOnly yes` is set).

---

## 5. Optional dev toolchains (still pending)

- **Node via nvm:** `~/.bashrc` has an NVM load block ready. Install nvm, then
  `nvm install <version>` + `nvm install --lts`.
- **Docker:** install, then restore `~/.docker/config.json`.
- VS Code and Neovim/LazyVim are covered by `bootstrap.sh` + the `nvim/` dotfiles.

---

## Backup / restore checklist (what is NOT in git)

| Item | Where it lives | On reinstall |
|------|----------------|--------------|
| SSH / GPG private keys | 1Password vaults | Sign in to 1Password |
| 1Password account | cloud | Sign in + re-approve device (YubiKey tap) |
| YubiKey credentials | the keys + this machine | Re-enroll (§3a) |
| TPM2 LUKS seal | this machine's TPM | Re-enroll (§2) |
| LUKS passphrase | your memory / password manager | Typed at install |
| `~/.ssh/csc.pub`, `csc-cert.pub` | 1Password / MyCSC | Re-export |
