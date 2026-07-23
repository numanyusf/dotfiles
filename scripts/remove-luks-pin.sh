#!/bin/bash
# Re-bind TPM2 auto-unlock for the LUKS root, with NO PIN.
# Use this after a firmware / Secure Boot update changes PCR 7 (boot then falls
# back to the LUKS passphrase — this re-seals the TPM to the new PCR 7).
#
# Your LUKS passphrase slot (slot 0) stays as fallback the whole time.
# You'll be prompted for your existing LUKS passphrase in step 2 (that's normal).
#
# The LUKS device is auto-detected from /etc/crypttab (so this works on any
# machine, not just the one it was written on). Override with an arg or env:
#   ./remove-luks-pin.sh /dev/nvme0n1p3
#   DEV=/dev/sda3 ./remove-luks-pin.sh
set -euo pipefail

# --- resolve the LUKS backing device ---------------------------------------
DEV="${1:-${DEV:-}}"

if [ -z "$DEV" ]; then
  # 2nd field of the first non-comment crypttab line, e.g. "UUID=520..." or "/dev/..."
  src=$(awk '!/^[[:space:]]*#/ && NF>=2 {print $2; exit}' /etc/crypttab 2>/dev/null || true)
  case "$src" in
    UUID=*) DEV=$(blkid -U "${src#UUID=}" || true) ;;
    /dev/*) DEV="$src" ;;
  esac
fi

if [ -z "$DEV" ]; then
  # last resort: first block device that is actually a LUKS container
  while read -r name _; do
    if sudo cryptsetup isLuks "/dev/$name" 2>/dev/null; then DEV="/dev/$name"; break; fi
  done < <(lsblk -rno NAME,TYPE | awk '$2=="part"||$2=="disk"{print $1}')
fi

if [ -z "$DEV" ] || ! sudo cryptsetup isLuks "$DEV" 2>/dev/null; then
  echo "!! Could not find a LUKS device (got: '${DEV:-none}')." >&2
  echo "   Pass it explicitly:  $0 /dev/nvmeXnYpZ" >&2
  exit 1
fi

echo ">> LUKS device: $DEV"
echo ">> Current keyslots:"
sudo cryptsetup luksDump "$DEV" | grep -E 'Keyslots:|^[[:space:]]+[0-9]+: luks2|tpm2' || true

echo ">> Step 1: removing the existing TPM2 keyslot..."
sudo systemd-cryptenroll --wipe-slot=tpm2 "$DEV" || echo "   (no tpm2 slot to wipe — continuing)"

echo ">> Step 2: re-enrolling TPM2 with NO PIN (enter your current LUKS passphrase when asked)..."
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 "$DEV"

echo ">> Done. Reboot to test — it should unlock with no PIN and no passphrase."
echo "   (To re-add a PIN instead, run with --tpm2-with-pin=yes — see docs/system-setup.md)"
