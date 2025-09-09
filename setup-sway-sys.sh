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
                    sway \
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

# --- 2. Network setup ---
echo "Setting static IP for interface ${INTERFACE}..."
CON_NAME=$(nmcli -t -f NAME connection show | grep "^${INTERFACE}$")
if [ -z "$CON_NAME" ]; then
    echo "No existing connection for ${INTERFACE}, creating one..."
    sudo nmcli connection add type ethernet ifname "${INTERFACE}" con-name "${INTERFACE}"
    CON_NAME="${INTERFACE}"
fi
sudo nmcli connection modify "$CON_NAME" ipv4.addresses "$IP_ADDRESS" ipv4.method manual
sudo nmcli connection up "$CON_NAME"
echo "Static IP $IP_ADDRESS applied to ${INTERFACE}."

echo "Checking device connection ${PING_TARGET}..."
ping -c 1 ${PING_TARGET} && echo "Ping success." || echo "Ping error."

# --- 3. Enable user linger ---
sudo loginctl enable-linger "${CURRENT_USER}"

# --- 4. Sway config ---
mkdir -p ~/.config/sway/
cp /etc/sway/config ~/.config/sway/config

# Comment out sway default wallpaper line
sed -i 's|^\(output \* bg .*\)|#\1|' ~/.config/sway/config

# Disable the default bar by commenting it out
sed -i '/^bar {/,/^}/ s/^/#/' ~/.config/sway/config

# Ensure custom settings are appended once
CUSTOM_CFG=$(cat <<'EOC'
# --- Custom GigE stream config ---
exec_always ~/RP5/gige.sh
exec_always swayidle -w timeout 0
seat * hide_cursor 1000
default_border none
default_floating_border none
bindsym $mod+Shift+Escape exec swaymsg exit
EOC
)

if ! grep -q "Custom GigE stream config" ~/.config/sway/config; then
    echo "$CUSTOM_CFG" >> ~/.config/sway/config
fi

# --- 5. Create system-wide systemd service ---
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

sudo tee "$SERVICE_PATH" > /dev/null << EOF
[Unit]
Description=GigE Camera Stream (Sway Wayland session)
After=graphical.target network.target seatd.service
Requires=seatd.service

[Service]
Type=simple
User=${CURRENT_USER}
Group=video
WorkingDirectory=/home/${CURRENT_USER}/RP5
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
StandardError=journal
ExecStartPre=/usr/bin/pkill -f 'sway|waylandsink' || true
ExecStartPre=/bin/rm -rf /run/user/%U/sway-ipc.* 2>/dev/null || true
ExecStart=/usr/bin/sway --unsupported-gpu
ExecStop=/usr/bin/pkill -f 'sway|waylandsink' || true
ExecStopPost=/bin/rm -rf /run/user/%U/sway-ipc.* 2>/dev/null || true
Restart=always
RestartSec=2
Environment="XDG_RUNTIME_DIR=/run/user/%U"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}"

echo "Setup complete. System-wide service '${SERVICE_NAME}' is enabled and will start on boot."
