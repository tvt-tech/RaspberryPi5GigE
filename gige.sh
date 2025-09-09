#!/bin/bash
set -e

source "$(dirname "$0")/config.sh"

# Отримання розміру екрану
SCREEN_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
SCREEN_WIDTH=$(echo $SCREEN_SIZE | cut -d',' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_SIZE | cut -d',' -f2)

# Глобальні змінні для відстеження стану
CURRENT_MODE=""
GSTREAMER_PID=""

# Функція для обчислення розмірів цілі
calculate_target_size() {
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
}

# Функція для запуску потоку з камери
start_camera_stream() {
    if [ "$CURRENT_MODE" != "camera" ]; then
        echo "$(date) - Camera found. Starting video stream."
        stop_current_stream
        
        calculate_target_size
        
        # Запуск GStreamer для камери у фоні
        gst-launch-1.0 -v aravissrc \
            ! video/x-raw,format=GRAY8,width=$SOURCE_WIDTH,height=$SOURCE_HEIGHT,framerate=25/1 \
            ! videoconvert \
            ! waylandsink sync=false &
        
        GSTREAMER_PID=$!
        CURRENT_MODE="camera"
        echo "$(date) - Camera stream started with PID $GSTREAMER_PID"
    fi
}

# Функція для запуску NO SIGNAL
start_no_signal() {
    if [ "$CURRENT_MODE" != "no_signal" ]; then
        echo "$(date) - Camera not found. Showing NO SIGNAL."
        stop_current_stream
        
        gst-launch-1.0 -v videotestsrc pattern=black \
            ! video/x-raw,width=$SCREEN_WIDTH,height=$SCREEN_HEIGHT,framerate=25/1 \
            ! videoconvert \
            ! textoverlay text="NO SIGNAL" font-desc="Sans 48" valignment=center \
            ! waylandsink sync=false &
        
        GSTREAMER_PID=$!
        CURRENT_MODE="no_signal"
        echo "$(date) - NO SIGNAL started with PID $GSTREAMER_PID"
    fi
}

# Функція для зупинки поточного потоку
stop_current_stream() {
    if [ ! -z "$GSTREAMER_PID" ] && kill -0 "$GSTREAMER_PID" 2>/dev/null; then
        echo "$(date) - Stopping current stream (PID $GSTREAMER_PID)"
        kill "$GSTREAMER_PID"
        wait "$GSTREAMER_PID" 2>/dev/null || true
    fi
    GSTREAMER_PID=""
}

# Функція для перевірки чи процес ще працює
check_process_alive() {
    if [ ! -z "$GSTREAMER_PID" ] && ! kill -0 "$GSTREAMER_PID" 2>/dev/null; then
        echo "$(date) - GStreamer process died unexpectedly, resetting"
        GSTREAMER_PID=""
        CURRENT_MODE=""
        return 1
    fi
    return 0
}

# Cleanup функція для коректного завершення
cleanup() {
    echo "$(date) - Cleaning up..."
    stop_current_stream
    exit 0
}

# Встановлення обробників сигналів
trap cleanup EXIT SIGTERM SIGINT

# Головний цикл
echo "$(date) - Starting camera monitor script"
echo "$(date) - Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

while true; do
    # Перевірка чи поточний процес ще живий
    check_process_alive
    
    # Перевірка доступності камери
    if ping -c 1 -W 1 "${PING_TARGET}" > /dev/null 2>&1; then
        # Камера доступна - запустити потік з камери
        start_camera_stream
    else
        # Камера недоступна - показати NO SIGNAL
        start_no_signal
    fi
    
    # Wait for next attempt
    sleep 1
done