#!/bin/bash
# Configure NetworkManager to use iwd as wifi backend (required for eduVPN)
sudo tee /etc/NetworkManager/conf.d/wifi-backend.conf > /dev/null << 'EOF'
[device]
wifi.backend=iwd
EOF

sudo systemctl enable --now NetworkManager
sudo systemctl restart NetworkManager
echo "NetworkManager configured with iwd backend."
