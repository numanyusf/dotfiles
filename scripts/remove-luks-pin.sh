#!/bin/bash
# Remove the TPM2 PIN from LUKS on /dev/nvme0n1p3, keeping TPM2 auto-unlock.
# Your LUKS passphrase slot (slot 0) stays as fallback the whole time.
# You'll be prompted for your existing LUKS passphrase in step 2 (that's normal).
set -e

DEV=/dev/nvme0n1p3

echo ">> Step 1: removing the PIN-bound TPM2 keyslot..."
sudo systemd-cryptenroll --wipe-slot=tpm2 "$DEV"

echo ">> Step 2: re-enrolling TPM2 with NO PIN (enter your current LUKS passphrase when asked)..."
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 "$DEV"

echo ">> Done. Reboot to test — it should unlock with no PIN and no passphrase."
