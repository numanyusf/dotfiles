#!/bin/bash
# Enable YubiKey tap-to-login for SDDM and hyprlock (falls back to password)
AUTHFILE=/etc/fido2/fido2
PAM_LINE="auth    sufficient pam_u2f.so cue authfile=$AUTHFILE"

for conf in /etc/pam.d/sddm /etc/pam.d/hyprlock; do
  if ! grep -q "pam_u2f.so" "$conf"; then
    sudo sed -i "1a $PAM_LINE" "$conf"
    echo "Added YubiKey auth to $conf"
  else
    echo "Already configured: $conf"
  fi
done
