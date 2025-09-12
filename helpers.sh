#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/config.sh"

# --- Install dependencies ---
function install_dependencies() {
    echo "Installing dependencies..."
    sudo apt update
    sudo apt install -y aravis-tools \
                        aravis-tools-cli \
                        libgstreamer1.0-dev \
                        gstreamer1.0-plugins-base \
                        gstreamer1.0-plugins-good \
                        gstreamer1.0-plugins-ugly \
                        gstreamer1.0-plugins-bad \
                        gstreamer1.0-libav \
                        gstreamer1.0-tools \
                        seatd \
    echo "Installation done."
}

# --- Add user to video/render/input groups ---
function setup_user_groups() {
    echo "Adding user '${CURRENT_USER}' to video/render/input groups..."
    sudo usermod -aG video,render,input "${CURRENT_USER}"
}

function setup_cage() {
    echo "Installing cage"
    sudo apt update
    sudo apt install -y cage
}

function setup_sway() {
    echo "Installing cage"
    sudo apt update
    sudo apt install -y cage
}

function ping_target() {
    echo "Static IP $IP_ADDRESS applied to ${INTERFACE}."
    echo "Checking device connection ${PING_TARGET}..."
    ping -c 1 ${PING_TARGET} && echo "Ping success." || echo "Ping error."
}

