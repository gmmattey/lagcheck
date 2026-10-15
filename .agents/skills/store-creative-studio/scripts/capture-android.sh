#!/bin/zsh
set -euo pipefail

if (( $# < 2 )); then
  print -u2 "Usage: $0 <package/activity> <output.png> [adb serial]"
  exit 64
fi

component="$1"
output="$2"
serial="${3:-}"
adb_args=()
[[ -n "$serial" ]] && adb_args=(-s "$serial")
mkdir -p "${output:h}"
adb "${adb_args[@]}" shell am start -n "$component" >/dev/null
sleep 2
adb "${adb_args[@]}" exec-out screencap -p > "$output"
print "Captured: $output"
