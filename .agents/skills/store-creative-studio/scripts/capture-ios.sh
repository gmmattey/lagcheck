#!/bin/zsh
set -euo pipefail

if (( $# < 3 )); then
  print -u2 "Usage: $0 <simulator-udid|booted> <bundle-id> <output.png> [launch arguments...]"
  exit 64
fi

device="$1"
bundle="$2"
output="$3"
shift 3

if [[ "$device" != "booted" ]]; then
  xcrun simctl boot "$device" 2>/dev/null || true
fi
xcrun simctl bootstatus "$device" -b
xcrun simctl terminate "$device" "$bundle" 2>/dev/null || true
xcrun simctl launch "$device" "$bundle" "$@" >/dev/null
sleep 2
mkdir -p "${output:h}"
xcrun simctl io "$device" screenshot "$output"
print "Captured: $output"
