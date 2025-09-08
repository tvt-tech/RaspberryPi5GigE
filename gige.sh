#!/bin/bash
set -e

source "$(dirname "$0")/config.sh"

SCREEN_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
SCREEN_WIDTH=$(echo $SCREEN_SIZE | cut -d',' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_SIZE | cut -d',' -f2)

while true; do
    if ping -c 1 -W 1 "${PING_TARGET}" > /dev/null 2>&1; then
        echo "$(date) - Camera found. Starting video stream."

        TARGET_WIDTH=$(awk "BEGIN {
            scale_x = $SCREEN_WIDTH / $SOURCE_WIDTH;
            scale_y = $SCREEN_HEIGHT / $SOURCE_HEIGHT;
            scale = (scale_x < scale_y) ? scale_x : scale_y;
            printf \"%.0f\", $SOURCE_WIDTH * scale
        }")
        TARGET_HEIGHT=$(awk "BEGIN {
            scale_x = $SCREEN_WIDTH / $SOURCE_WIDTH;
            scale_y = $SCREEN_HEIGHT / $SOURCE_HEIGHT;
            scale = (scale_x < scale_y) ? scale_x : scale_y;
            printf \"%.0f\", $SOURCE_HEIGHT * scale
        }")
        TARGET_WIDTH=$(( (TARGET_WIDTH / 2) * 2 ))
        TARGET_HEIGHT=$(( (TARGET_HEIGHT / 2) * 2 ))

        # Запускаємо GStreamer для камери
        gst-launch-1.0 -v aravissrc \
            ! video/x-raw,format=GRAY8,width=$SOURCE_WIDTH,height=$SOURCE_HEIGHT,framerate=25/1 \
            ! videoconvert \
            ! waylandsink
    else
        echo "$(date) - Camera not found. Showing NO SIGNAL."
        gst-launch-1.0 -v videotestsrc pattern=black \
            ! videoconvert \
            ! textoverlay text="NO SIGNAL" font-desc="Sans 48" valignment=center \
            ! waylandsink
    fi

    # Чекаємо кілька секунд перед наступною перевіркою
    sleep 5
done
