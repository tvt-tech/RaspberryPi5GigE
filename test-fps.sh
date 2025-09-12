#!/bin/bash

# Define default values
source_type="pattern"
framerate="144/1"
out_width=640
out_height=512
sink_type="autovideosink"

# Process command line arguments
while getopts "s:r:f:d:" opt; do
  case ${opt} in
    s )
      source_type=$OPTARG
      ;;
    r )
      resolution=$OPTARG
      IFS='x' read -ra RES_PARTS <<< "$resolution"
      out_width=${RES_PARTS[0]}
      out_height=${RES_PARTS[1]}
      ;;
    f )
      framerate=$OPTARG
      ;;
    d )
      sink_type=$OPTARG
      ;;
    \? )
      echo "Usage: $0 [-s pattern|stream] [-r WxH] [-f FRAMERATE] [-d waylandsink|kmssink|autovideosink|fbdevsink|glimagesink]"
      exit 1
      ;;
  esac
done

# Set source and input capabilities
if [ "$source_type" == "pattern" ]; then
    source_pipeline="videotestsrc pattern=ball is-live=true"
else
    source_pipeline="aravissrc"
fi

# Вхідна роздільна здатність завжди 640x512
in_width=640
in_height=512

# Caps для вхідного потоку
input_caps="video/x-raw,format=GRAY8,width=$in_width,height=$in_height,framerate=$framerate"
if [ "$sink_type" == "glimagesink" ]; then
    # glimagesink вимагає інший формат, тому формат GRAY8 не підійде
    input_caps="video/x-raw,width=$in_width,height=$in_height,framerate=$framerate"
fi

# Встановлення елементів для масштабування
scale_pipeline="videoscale ! video/x-raw,width=$out_width,height=$out_height"

# Встановлення елементів для конвертації
if [ "$sink_type" == "glimagesink" ]; then
    extra_elements="! glupload ! glcolorconvert"
else
    extra_elements="! videoconvert"
fi

# Construct the full GStreamer pipeline
GST_DEBUG=fpsdisplaysink:5 gst-launch-1.0 -v $source_pipeline \
        ! $input_caps \
        ! $scale_pipeline \
        $extra_elements \
        ! fpsdisplaysink signal-fps-measurements=true text-overlay=true video-sink=$sink_type sync=false