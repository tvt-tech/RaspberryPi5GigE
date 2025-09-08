#!/bin/bash
set -e

source "$(dirname "$0")/config.sh"

SCREEN_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
SCREEN_WIDTH=$(echo $SCREEN_SIZE | cut -d',' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_SIZE | cut -d',' -f2)

NO_SIGNAL_PID=

show_no_signal() {
    gst-launch-1.0 -v videotestsrc pattern=black \
        ! videoconvert \
        ! textoverlay text="NO SIGNAL" font-desc="Sans 48" valignment=center \
        ! waylandsink &
    NO_SIGNAL_PID=$!
}

kill_no_signal() {
    if [ -n "$NO_SIGNAL_PID" ]; then
        kill $NO_SIGNAL_PID || true
        wait $NO_SIGNAL_PID 2>/dev/null || true
        NO_SIGNAL_PID=
    fi
}

while true; do
    if ping -c 1 -W 1 "${PING_TARGET}" > /dev/null 2>&1; then
        echo "$(date) - Camera found. Starting video stream."
        kill_no_signal

        gst-launch-1.0 -v aravissrc \
            ! video/x-raw,format=GRAY8,width=$SOURCE_WIDTH,height=$SOURCE_HEIGHT,framerate=25/1 \
            ! videoconvert \
            ! waylandsink

        # якщо gst-launch впаде — цикл повториться
    else
        echo "$(date) - Camera not found."
        if [ -z "$NO_SIGNAL_PID" ]; then
            show_no_signal
        fi
    fi

    sleep 5
done
