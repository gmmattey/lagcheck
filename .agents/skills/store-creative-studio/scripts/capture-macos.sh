#!/bin/zsh
set -euo pipefail

if (( $# < 1 || $# > 2 )); then
  print -u2 "Usage: $0 <output.png> [window-id]"
  exit 64
fi

output="$1"
window_id="${2:-}"
mkdir -p "${output:h}"
if [[ -n "$window_id" ]]; then
  screencapture -x -l"$window_id" "$output"
else
  screencapture -x "$output"
fi
print "Captured: $output"
