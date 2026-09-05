#!/usr/bin/env bash
# Tail only what matters. Usage: bash scripts/capture-logs.sh [device-serial]
set -euo pipefail
DEVICE_ARG=""
if [ $# -ge 1 ]; then DEVICE_ARG="-s $1"; fi
adb $DEVICE_ARG logcat -c
echo "==> tailing Sarthi + crashes. Ctrl-C to stop."
adb $DEVICE_ARG logcat | grep --line-buffered -E "Sarthi|AndroidRuntime|FATAL|MediaPipe|MLKit"
