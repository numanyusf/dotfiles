#!/bin/bash
# Enable YubiKey tap-to-login for SDDM and hyprlock (falls back to password)
AUTHFILE=/etc/fido2/fido2
PAM_LINE="auth    sufficient pam_u2f.so cue authfile=$AUTHFILE"

# Grant sddm access to FIDO2/U2F devices (needed before login session exists)
sudo tee /etc/udev/rules.d/70-fido2-sddm.rules > /dev/null << 'UDEVEOF'
SUBSYSTEM=="hidraw", ENV{ID_SECURITY_TOKEN}=="1", GROUP="sddm", MODE="0660"
UDEVEOF
sudo udevadm control --reload-rules

for conf in /etc/pam.d/sddm /etc/pam.d/hyprlock; do
  if ! grep -q "pam_u2f.so" "$conf"; then
    sudo sed -i "1a $PAM_LINE" "$conf"
    echo "Added YubiKey auth to $conf"
  else
    echo "Already configured: $conf"
  fi
done
