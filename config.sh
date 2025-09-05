#!/bin/bash

# Network configuration
INTERFACE="eth0"
IP_ADDRESS="10.0.5.100/8"
PING_TARGET="10.0.5.244"

# GStreamer stream configuration
SOURCE_WIDTH=640
SOURCE_HEIGHT=512
RETRY_TIMEOUT=5  # Delay before next launch attempt (in seconds)

# Systemd service configuration
SERVICE_FILE="/etc/systemd/system/gige-stream.service"
SERVICE_NAME="gige-stream.service"