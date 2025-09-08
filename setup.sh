#!/bin/bash

# --- Include configuration ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/config.sh"

# Detect current user and home directory
CURRENT_USER=$(whoami)
CURRENT_USER_HOME=$(eval echo "~$CURRENT_USER")
# --- Get the current user's ID ---
CURRENT_USER_ID=$(id -u "${CURRENT_USER}")

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
                     gstreamer1.0-tools

echo "Installation done."

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
    ipv4.gateway "10.0.0.1" ipv4.dns "10.0.0.1 8.8.8.8" ipv4.method manual

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

# Using 'here document' to write service content to the file
sudo tee "${SERVICE_FILE}" > /dev/null << EOF
[Unit]
Description=Gige Camera Stream Service
After=network.target

[Service]
Type=simple
User=${CURRENT_USER}
Group=video
Restart=always
RestartSec=1s
WorkingDirectory=${SCRIPT_DIR}
ExecStart=/bin/bash ${SCRIPT_DIR}/gige.sh
ExecStop=/usr/bin/pkill -f "/bin/bash ${SCRIPT_DIR}/gige.sh"
TimeoutStopSec=5
Environment="XDG_RUNTIME_DIR=/run/user/${CURRENT_USER_ID}"

[Install]
WantedBy=multi-user.target
EOF

# Reloading systemd
sudo systemctl daemon-reload

# Enable and immediately restart the service
sudo systemctl enable --now "${SERVICE_NAME}"

echo "Service ${SERVICE_NAME} creation and start done."