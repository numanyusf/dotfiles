#!/bin/bash
# Always use balanced power profile by default; switch manually via Fn+Q
sudo tee /etc/udev/rules.d/99-power-profile.rules > /dev/null << 'EOF'
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/bin/systemd-run --no-block --collect --property=After=power-profiles-daemon.service /usr/bin/powerprofilesctl set balanced"
SUBSYSTEM=="power_supply", ATTR{type}=="USB", RUN+="/usr/bin/systemd-run --no-block --collect --property=After=power-profiles-daemon.service /usr/bin/powerprofilesctl set balanced"
EOF

sudo udevadm control --reload-rules
powerprofilesctl set balanced
echo "Power profile set to balanced by default."
