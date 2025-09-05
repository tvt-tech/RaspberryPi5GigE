#!/bin/bash

# --- Include configuration ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/config.sh"

# Detect current user and home directory
CURRENT_USER=$(whoami)
CURRENT_USER_HOME=$(eval echo "~$CURRENT_USER")

# --- 1. Setup dependencies ---
echo "Installing dependencies..."
sudo apt update
sudo apt install -y aravis-tools \
                     libgstreamer1.0-dev \
                     gstreamer1.0-plugins-base \
                     gstreamer1.0-plugins-good \
                     gstreamer1.0-plugins-ugly \
                     gstreamer1.0-plugins-bad \
                     libgtk-3-dev \
                     gstreamer1.0-tools

echo "Installation done."

# --- 2. Network setup ---
echo "Setting up network interface ${INTERFACE}..."

# Add static IP-address to configuration file
echo "
interface ${INTERFACE}
static ip_address=${IP_ADDRESS}
" | sudo tee -a /etc/dhcpcd.conf > /dev/null

# Clean up existing IP-addresses
sudo ip addr flush dev ${INTERFACE}

# Assign new static IP-address (for current session)
sudo ip addr add ${IP_ADDRESS} dev ${INTERFACE}

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
Description=Gige Camera Stream Monitoring Service
After=network.target

[Service]
Type=simple
User=${CURRENT_USER}
Group=video
Restart=always
RestartSec=5s
WorkingDirectory=${SCRIPT_DIR}
ExecStart=/bin/bash ${SCRIPT_DIR}/start.sh

[Install]
WantedBy=multi-user.target
EOF

# Reloading systemd
sudo systemctl daemon-reload

# Enable and immediately restart the service
sudo systemctl enable --now "${SERVICE_NAME}"

echo "Service ${SERVICE_NAME} creation and start done."