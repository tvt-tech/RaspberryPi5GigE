#!/bin/bash

# --- Include configuration ---
source ./config.sh

# Detect screen resolution
SCREEN_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
SCREEN_WIDTH=$(echo $SCREEN_SIZE | cut -d',' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_SIZE | cut -d',' -f2)

# Ping the camera to check for connectivity
if ping -c 1 -W 1 "${PING_TARGET}" > /dev/null 2>&1; then
    echo "Camera found. Starting video stream."

    # Calculate scaling coefficients and select smaller
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

    # Round to even numbers
    TARGET_WIDTH=$(( (TARGET_WIDTH / 2) * 2 ))
    TARGET_HEIGHT=$(( (TARGET_HEIGHT / 2) * 2 ))

    echo "Calculated target size: ${TARGET_WIDTH}x${TARGET_HEIGHT}"

    # Launch GStreamer with aravissrc
    cage -s -- gst-launch-1.0 -v aravissrc \
        ! video/x-raw,format=GRAY8,width=$SOURCE_WIDTH,height=$SOURCE_HEIGHT,framerate=25/1 \
        ! tee name=t \
            t. \
            ! videoconvert \
            ! waylandsink
else
    echo "Camera not found. Displaying 'NO SIGNAL' screen."
    
    # Launch GStreamer with videotestsrc
    cage -s -- gst-launch-1.0 -v videotestsrc pattern=black \
        ! videoconvert \
        ! textoverlay text="NO SIGNAL" font-desc="Sans 48" valignment=center \
        ! waylandsink
fi