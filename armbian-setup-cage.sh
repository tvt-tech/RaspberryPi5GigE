#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/config.sh"

CURRENT_USER=$(whoami)

# --- 1. Install dependencies ---
echo "Installing dependencies..."
sudo apt update
sudo apt install -y aravis-tools \
                    aravis-tools-cli \
                    cage \
                    libgstreamer1.0-dev \
                    gstreamer1.0-plugins-base \
                    gstreamer1.0-plugins-good \
                    gstreamer1.0-plugins-ugly \
                    gstreamer1.0-plugins-bad \
                    gstreamer1.0-libav \
                    gstreamer1.0-tools \
                    seatd
echo "Installation done."

# --- 1.1 Add user to video/render/input groups ---
echo "Adding user '${CURRENT_USER}' to video/render/input groups..."
sudo usermod -aG video,render,input "${CURRENT_USER}"

# --- 2. Network setup for Armbian (Netplan) ---
echo "Setting static IP for interface end1 using Netplan..."

NETPLAN_FILE="/etc/netplan/99-static-camera.yaml"

# Create the netplan config file
sudo tee "${NETPLAN_FILE}" > /dev/null << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    end1:
      dhcp4: false
      addresses:
        - ${IP_ADDRESS}
EOF

# Apply the netplan configuration
echo "Applying Netplan configuration..."
sudo netplan apply

# Verify the new IP address
echo "Checking if the static IP was applied to 'end1'..."
ip_check=$(ip -4 addr show end1 | grep 'inet ' | awk '{print $2}')
if [[ "$ip_check" == "${IP_ADDRESS}" ]]; then
    echo "Static IP ${IP_ADDRESS} successfully applied."
else
    echo "Failed to apply static IP. Current IP: ${ip_check}"
    exit 1
fi

echo "Checking device connection to ${PING_TARGET}..."
ping -c 1 "${PING_TARGET}" && echo "Ping success." || echo "Ping error."

# --- 3. Enable user linger for systemd user service ---
sudo loginctl enable-linger "${CURRENT_USER}"

# --- 4. Create user-level systemd service ---
USER_SYSTEMD_DIR="${HOME}/.config/systemd/user"
mkdir -p "${USER_SYSTEMD_DIR}"

tee "${USER_SYSTEMD_DIR}/${SERVICE_NAME}" > /dev/null << EOF
[Unit]
Description=GigE Camera Stream (Cage Wayland session)
After=network.target seatd.service

[Service]
Type=simple
ExecStart=/usr/bin/cage -s -- ${SCRIPT_DIR}/gige.sh
Restart=always
RestartSec=1
Environment="XDG_RUNTIME_DIR=/run/user/%U"
WorkingDirectory=${SCRIPT_DIR}

[Install]
WantedBy=default.target
EOF

# Reload user systemd and enable service
systemctl --user daemon-reload
systemctl --user enable --now "${SERVICE_NAME}"

echo "Setup complete. Service '${SERVICE_NAME}' will start automatically after user login."
