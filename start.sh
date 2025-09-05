#!/bin/bash

# --- Include configuration ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/config.sh"

# Detect screen resolution just once
SCREEN_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
SCREEN_WIDTH=$(echo $SCREEN_SIZE | cut -d',' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_SIZE | cut -d',' -f2)

# Stream setup
STREAM_SCRIPT="${SCRIPT_DIR}/gige.sh"
RETRY_TIMEOUT=5  # Delay before next launch attempt (in seconds)

# --- Function to display "NO SIGNAL" screensaver ---
show_no_signal() {
    if pgrep -f "videotestsrc pattern=no-signal" > /dev/null; then
        return
    fi

    cat /dev/zero > /dev/fb0

    gst-launch-1.0 -v videotestsrc pattern=no-signal \
    ! videoscale \
    ! video/x-raw,width=${SCREEN_WIDTH},height=${SCREEN_HEIGHT} \
    ! fbdevsink > /dev/null 2>&1 &

    echo "Display NO SIGNAL screensaver..."
}

# --- Function to stop "NO SIGNAL" screensaver ---
stop_no_signal() {
    pkill -f "videotestsrc pattern=no-signal"
}

# --- Main watchdog loop ---
while true; do
    if pgrep -f "aravissrc" > /dev/null; then
        stop_no_signal
        echo "Stream gige.sh working. Monitoring..."
        sleep $RETRY_TIMEOUT
    else
        echo "Stream gige.sh not found. Restart..."
        show_no_signal
        nohup "$STREAM_SCRIPT" > /dev/null 2>&1 &
        sleep $RETRY_TIMEOUT
    fi
done