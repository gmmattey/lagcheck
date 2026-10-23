#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "$0")" && pwd)"

ffmpeg -y \
  -i "$root_dir/source-check-user-supplied.mp4" \
  -loop 1 -framerate 30 -t 3 -i "$root_dir/source-not-ready-user-supplied.png" \
  -filter_complex "[1:v]scale=-2:1840,setsar=1[screen];color=c=0x0B0D10:s=1080x1920:r=30:d=3[base];[base][screen]overlay=(W-w)/2:(H-h)/2,format=yuv420p[card];[0:v]settb=AVTB,setpts=PTS-STARTPTS[check];[card]settb=AVTB,setpts=PTS-STARTPTS[endcard];[check][endcard]xfade=transition=fade:duration=0.5:offset=13.5,format=yuv420p[video]" \
  -map "[video]" \
  -an \
  -c:v libx264 -crf 18 -preset medium -movflags +faststart \
  "$root_dir/05-check-to-not-ready.mp4"
