#!/bin/bash
# Enable YubiKey tap-to-unlock for hyprlock (falls back to password).
# Note: SDDM uses autologin, so its greeter never appears — no pam_u2f there.
# sudo/polkit FIDO2 is handled separately by omarchy-setup-security-fido2.
# LUKS disk unlock uses FIDO2 via sd-encrypt (see setup notes), not PAM.
AUTHFILE=/etc/fido2/fido2
PAM_LINE="auth    sufficient pam_u2f.so cue authfile=$AUTHFILE"

conf=/etc/pam.d/hyprlock
if ! grep -q "pam_u2f.so" "$conf"; then
  sudo sed -i "1a $PAM_LINE" "$conf"
  echo "Added YubiKey auth to $conf"
else
  echo "Already configured: $conf"
fi
