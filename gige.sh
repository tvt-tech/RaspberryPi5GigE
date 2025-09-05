#!/bin/bash

# --- Include configuration ---
source ./config.sh

# Detect screen resolution
SCREEN_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
SCREEN_WIDTH=$(echo $SCREEN_SIZE | cut -d',' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_SIZE | cut -d',' -f2)

echo "Source video: ${SOURCE_WIDTH}x${SOURCE_HEIGHT}"
echo "Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

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

# Round to pair numbers
TARGET_WIDTH=$(( (TARGET_WIDTH / 2) * 2 ))
TARGET_HEIGHT=$(( (TARGET_HEIGHT / 2) * 2 ))

echo "Calculated target size: ${TARGET_WIDTH}x${TARGET_HEIGHT}"

# Fill screen with black before stream start
cat /dev/zero > /dev/fb0

# Launch GStreamer
gst-launch-1.0 -v aravissrc \
  ! video/x-raw,format=GRAY8,width=$SOURCE_WIDTH,height=$SOURCE_HEIGHT,framerate=25/1 \
  ! tee name=t \
    t. \
    ! queue \
    ! videoconvert \
    ! videoscale method=bilinear add-borders=true \
    ! video/x-raw,width=$TARGET_WIDTH,height=$TARGET_HEIGHT \
    ! fbdevsink 
    # \
    # t. \
    # ! queue \
    # ! videoconvert \
    # ! video/x-raw,format=NV12 \
    # ! v4l2h264enc \
    # ! h264parse \
    # ! mp4mux \
    # ! filesink location=output.mp4