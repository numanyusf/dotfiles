# Ubuntu setup guide — full walkthrough

The complete, ordered runbook for taking a **Lenovo Legion S7 16IAH7** from a
blank disk to the fully-configured Ubuntu (GNOME) environment in this repo.
Follow it top to bottom on a fresh install. Deep-dive detail for the tricky
`/etc` pieces lives in [`system-setup.md`](system-setup.md); this guide is the
map that puts everything in sequence.

> **What you end up with:** full-disk LUKS encryption that auto-unlocks via TPM2,
> YubiKey tap-to-sudo/login, 1Password-backed SSH + git commit signing, a
> One-Dark Ptyxis + oh-my-posh + eza terminal, Neovim/LazyVim, and VS Code.
>
> **Time:** ~30–45 min hands-on (plus download time).

---

## Stage 0 — Before you install

- **Have ready:** the Ubuntu ISO on a USB, your **LUKS passphrase** (memorised or
  in a password manager), your **1Password** account credentials, and both
  **YubiKeys**.
- **Machine facts** you'll rely on later: NVMe disk, NVIDIA RTX 3060 Mobile +
  Intel Iris Xe, Secure Boot capable, TPM2 present. Boot uses **dracut** (not
  initramfs-tools). See [`system-setup.md` §0](system-setup.md).

---

## Stage 1 — Install Ubuntu

1. Boot the USB, choose **Interactive / full install** (include third-party
   drivers for NVIDIA/media).
2. **Disk:** erase the whole disk (this wipes Windows) and choose **"Encrypt the
   new Ubuntu installation" with a passphrase (LVM + LUKS)**.
   - ⚠️ Do **not** pick the installer's "hardware-backed"/TPM FDE option — it
     fails on this laptop (Intel Boot Guard is fused by Lenovo and the installer
     precheck rejects it). Use a **normal LUKS passphrase now**; we add TPM2
     auto-unlock in Stage 6.
3. Leave **Secure Boot enabled**. Finish install, reboot, remove the USB.

At first boot you'll be prompted for the **LUKS passphrase** (this changes to
automatic in Stage 6).

---

## Stage 2 — First boot: update system + firmware

```bash
sudo apt update && sudo apt full-upgrade -y
sudo fwupdmgr refresh && sudo fwupdmgr get-updates
sudo fwupdmgr update          # apply UEFI db/dbx etc., then reboot if asked
```

Do firmware updates **before** sealing the TPM (Stage 6) — a later firmware
update changes PCR 7 and would break the TPM seal (recoverable, but avoid the
round-trip). See [`system-setup.md` §2](system-setup.md).

---

## Stage 3 — Clone the dotfiles and run bootstrap

```bash
sudo apt install -y git
git clone https://github.com/numanyusf/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && git checkout ubuntu
./bootstrap.sh
```

`bootstrap.sh` (idempotent — safe to re-run) does all of this for you:

- **Preflight:** checks OS = Ubuntu, version ≥ 24.04, GNOME, user = `numan`
  (warns + prompts if anything differs).
- **apt repos + keys:** 1Password, VS Code (Microsoft), Firefox (Mozilla `.deb`,
  pinned so it can't revert to snap), eduVPN.
- **Packages:** everything in [`packages.txt`](../packages.txt) — CLI/build tools,
  eza/vivid/tmux, the Neovim toolchain, LUKS/TPM tools, YubiKey/PAM tools.
- **Third-party apps:** `1password`, `1password-cli`, `code`, `firefox`,
  `eduvpn-client`.
- **oh-my-posh + MesloLGM Nerd Font.**
- **Symlinks:** `~/.bashrc`, `~/.gitconfig`, `~/.config/{oh-my-posh,nvim,tmux}`,
  `~/.ssh/{config,allowed_signers}`, `~/.config/1Password/ssh/agent.toml`.
- **tmux/TPM** and **Ptyxis dconf** restore.

When it finishes it prints the manual steps that follow (Stages 4–7).

---

## Stage 4 — 1Password + Firefox + SSH agent

These need you to sign in / click UI — they can't be scripted.

1. **1Password desktop app:** launch it, sign in to your account
   (`numan.yusf@gmail.com`, my.1password.com). Approving a new device will ask
   for a **YubiKey tap** (2FA).
2. In **Settings → Developer**, enable:
   - **"Use the SSH agent"** (the dotfiles already point `~/.ssh/config` at
     `~/.1password/agent.sock`, and `agent.toml` exposes vaults
     **Private / Work / Development** — where the GitHub keys live).
   - **"Integrate with 1Password CLI"** (`op`).
3. **Firefox extension:** in Firefox install the **1Password** extension from
   addons.mozilla.org and approve the desktop-app connection. (This is why we use
   the Mozilla `.deb`, not the snap — the snap is sandboxed and can't reach the
   app via native-messaging.)

---

## Stage 5 — git signing + GitHub auth

`~/.gitconfig` is already configured for SSH commit signing via 1Password
(`op-ssh-sign`, `commit.gpgsign=true`). Verify and authenticate:

```bash
gh auth login                 # HTTPS, token to keyring — powers the git credential helper
# test signing:
cd /tmp && git init -q sigtest && cd sigtest && git commit -q --allow-empty -m test
git log --show-signature -1   # expect: Good "git" signature ... ED25519
cd .. && rm -rf sigtest
```

**CSC hosts** (`lumi`/`puhti`/`roihu`) are in `~/.ssh/config` but need
`~/.ssh/csc.pub` / `csc-cert.pub` — export them from 1Password or MyCSC on first
connect (`IdentitiesOnly yes` is set).

---

## Stage 6 — LUKS TPM2 auto-unlock

Turn the passphrase prompt at boot into automatic TPM2 unlock (passphrase stays
as fallback). Full detail + gotchas in [`system-setup.md` §2](system-setup.md);
the short version (run in your **own** terminal — it asks for the passphrase):

```bash
# tpm2-tools is already installed by bootstrap (dracut needs the tpm2 binary)
# no-PIN unlock (current choice):
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3
sudo cp /etc/crypttab /etc/crypttab.pre-tpm.bak
# edit the root line's options to:  luks,tpm2-device=auto
sudo dracut --force /boot/initrd.img-"$(uname -r)" "$(uname -r)"
sudo reboot                   # should now unlock without a prompt
```

⚠️ If a future firmware/Secure Boot update changes PCR 7, boot falls back to the
passphrase (no lockout) — re-seal with `scripts/remove-luks-pin.sh` (auto-detects
the disk).

---

## Stage 7 — YubiKey tap-to-sudo and tap-to-login

Enroll both keys and wire them into PAM. Full detail in
[`system-setup.md` §3](system-setup.md). Summary:

1. Enroll each key (needs the key present + FIDO2 PIN + touch), merged onto one
   line in `~/.config/Yubico/u2f_keys`.
2. Add `auth sufficient pam_u2f.so openasuser cue` **before** `@include
   common-auth` in **both** `/etc/pam.d/sudo` and `/etc/pam.d/gdm-password`
   (back up the originals first — `sufficient` means no key → falls back to
   password, so you can't lock yourself out).
3. Register both keys as FIDO2 two-factor on your 1Password account (web UI).

Validate without logging out: `pamtester gdm-password numan authenticate` (tap →
"successfully authenticated").

---

## Stage 8 — Terminal look (already applied by bootstrap)

Open a **new** Ptyxis tab and you should see the themed prompt. What's in place:

- **Ptyxis:** `MesloLGM Nerd Font 13` (the **non-Mono** variant — Mono shrinks the
  prompt icons), built-in **One Dark** palette, opacity `0.9`. Set via
  `ptyxis.dconf`. GNOME accent is Yaru **orange**, `prefer-dark`.
- **oh-my-posh** (`emodipt-extend`): One Dark colors — path **gold** `#E5C07B`,
  time **green**, shell **coral** `#E06C75`; segments for git, node/python +
  other language versions, battery, SSH host, exec-time, status. Language/battery
  segments auto-hide when not applicable.
- **eza** replaces `ls` (Nerd Font icons); `LS_COLORS` from **vivid** one-dark
  with directories overridden to gold. Aliases: `ls`/`ll`/`la`/`l`/`lt`.

To replicate **just the prompt** on another distro/terminal, see the standalone
handout [`oh-my-posh-portable.md`](oh-my-posh-portable.md).

Note: editing the `.omp.json`? run `oh-my-posh cache clear` after.

---

## Stage 9 — Editors

- **Neovim = LazyVim** (installed by bootstrap; config in `~/.config/nvim` →
  repo). Launch `nvim` once — LazyVim bootstraps `lazy.nvim`, plugins, treesitter
  parsers, and Mason LSPs (basedpyright/ruff, vtsls, sqlls, json/yaml/lua,
  docker, terraform, tailwind, marksman). Colorscheme = **One Dark**
  (`navarasu/onedark.nvim`) to match the terminal.
- **VS Code** (`code`, from the Microsoft repo). Its git commits auto-sign via the
  system gitconfig (1Password op-ssh-sign).

---

## Stage 10 — Dev toolchains (optional, still open)

- **Node via nvm:** `~/.bashrc` has an NVM load block ready. Install nvm, then
  `nvm install --lts` (and any specific version you need). *(apt `nodejs` is also
  present from the Neovim toolchain.)*
- **Docker:** install, then restore `~/.docker/config.json`.
- Other runtimes (Rust, Go, Java, Python `uv`) — add as needed; the oh-my-posh
  language segments light up automatically once each runtime is installed.

---

## Stage 11 — Hardware notes (Legion S7)

- **NVIDIA:** `sudo ubuntu-drivers install` (last pinned `nvidia-driver-595-open`),
  CUDA 13.2, Prime **on-demand**, MOK-signed so it loads under Secure Boot.
- **Battery:** conservation mode ON caps charge at ~85% (shown as 100%) — not
  wear; toggle `/sys/bus/platform/devices/VPC2004:00/conservation_mode` for true 100%.
- **Webcam:** Chicony USB (uvcvideo); only enumerates when the **physical privacy
  switch is ON**. No IPU6 driver needed.
- **Fingerprint** (Elan) works with fprintd; enrollment skipped by choice.

---

## Stage 12 — Verify everything

```bash
oh-my-posh --version          # prompt binary
ls                            # eza icons + gold dirs, themed
git log --show-signature -1   # Good git signature (in any signed repo)
gh auth status                # logged in
lsblk                         # LUKS + LVM layout
sudo cryptsetup luksDump /dev/nvme0n1p3 | grep -A1 Keyslots  # slot 0 pass, slot 1 tpm2
sudo id                       # YubiKey tap -> uid=0
code --version ; nvim --version | head -1
```

Reboot once more: it should TPM2-unlock the disk automatically, then let you log
in with a YubiKey tap.

---

## What is NOT in git (and how it's restored)

| Item | Where it lives | On a fresh install |
|------|----------------|--------------------|
| SSH / GPG private keys | 1Password vaults | Sign in to 1Password |
| 1Password account | cloud | Sign in + YubiKey-tap the new device |
| YubiKey credentials | the keys + this machine | Re-enroll (Stage 7) |
| TPM2 LUKS seal | this machine's TPM | Re-enroll (Stage 6) |
| LUKS passphrase | your memory / password manager | Typed at install |
| `~/.ssh/csc.pub`, `csc-cert.pub` | 1Password / MyCSC | Re-export |

Everything else — configs, package list, install automation, and these docs — is
in this repo. See the [README](../README.md) for the file-by-file map.
