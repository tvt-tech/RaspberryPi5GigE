#!/bin/bash
set -e

# --- Include configuration ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/config.sh"

CURRENT_USER=$(whoami)

# --- 1. Setup dependencies ---
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

# --- 1.1. Set permissions for display access ---
echo "Adding user '${CURRENT_USER}' to 'video', 'render' and 'input' groups..."
sudo usermod -aG video,render,input "${CURRENT_USER}"

# Enable seatd
sudo systemctl enable --now seatd.service

# --- 2. Network setup ---
echo "Setting static IP for interface ${INTERFACE}..."

# Check exist connection
CON_NAME=$(nmcli -t -f NAME connection show | grep "^${INTERFACE}$")

if [ -z "$CON_NAME" ]; then
    echo "No existing connection for ${INTERFACE}, creating one..."
    sudo nmcli connection add type ethernet ifname "${INTERFACE}" con-name "${INTERFACE}"
    CON_NAME="${INTERFACE}"
fi

# Set static IP
sudo nmcli connection modify "$CON_NAME" ipv4.addresses "$IP_ADDRESS" \
    ipv4.method manual

# Activate
sudo nmcli connection up "$CON_NAME"

echo "Static IP $IP_ADDRESS applied to ${INTERFACE}."

# --- 2.1. Check connection ---
echo "Checking device connection ${PING_TARGET}..."
ping -c 1 ${PING_TARGET}

if [ $? -eq 0 ]; then
    echo "Ping success. Network correctly set."
else
    echo "Ping error. Check connection and IP-address."
fi

# --- 3. Creating and enabling systemd service ---
echo "Creating and enabling systemd service..."


sudo tee "/etc/systemd/system/${SERVICE_NAME}" > /dev/null << EOF
[Unit]
Description=GigE Camera Stream (Cage Wayland session)
After=network-online.target seatd.service
Requires=seatd.service
Wants=network-online.target

[Service]
User=${CURRENT_USER}
Group=video
WorkingDirectory=${SCRIPT_DIR}
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
StandardError=journal
ExecStart=/usr/bin/cage -s -- ${SCRIPT_DIR}/gige.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}"

echo "Service ${SERVICE_NAME} creation and start done."
