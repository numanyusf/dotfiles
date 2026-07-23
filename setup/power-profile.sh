#!/bin/bash
# Always use balanced power profile by default; switch manually via Fn+Q

# udev rule for plug/unplug events
sudo tee /etc/udev/rules.d/99-power-profile.rules > /dev/null << 'EOF'
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/bin/systemd-run --no-block --collect --property=After=power-profiles-daemon.service /usr/bin/powerprofilesctl set balanced"
EOF

# systemd service for boot-time default (WantedBy=graphical.target avoids ordering cycle with multi-user.target)
sudo tee /etc/systemd/system/power-profile-balanced.service > /dev/null << 'EOF'
[Unit]
Description=Set balanced power profile at startup
After=power-profiles-daemon.service

[Service]
Type=oneshot
ExecStart=/usr/bin/powerprofilesctl set balanced
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now power-profile-balanced.service
sudo udevadm control --reload-rules
powerprofilesctl set balanced
echo "Power profile set to balanced by default."
