#!/usr/bin/env bash
# Push runtime config from the repo to the device.
# Usage: bash scripts/push-config.sh [device-serial]
set -euo pipefail

DEVICE_ARG=""
if [ $# -ge 1 ]; then DEVICE_ARG="-s $1"; fi

DEST_PRIMARY="/sdcard/EyesUp/config"
DEST_FALLBACK="/sdcard/Android/data/com.eyesup.app/files/config"

echo "==> devices"
adb devices

echo "==> creating $DEST_PRIMARY"
if adb $DEVICE_ARG shell "mkdir -p $DEST_PRIMARY" 2>/dev/null; then
  DEST="$DEST_PRIMARY"
else
  echo "    /sdcard/EyesUp not writable (scoped storage) - falling back"
  adb $DEVICE_ARG shell "mkdir -p $DEST_FALLBACK"
  DEST="$DEST_FALLBACK"
  echo "    !! Update ConfigRepository's path to $DEST and note it in PROGRESS.md"
fi

for f in assets/config/*.json; do
  echo "==> pushing $(basename "$f") -> $DEST"
  adb $DEVICE_ARG push "$f" "$DEST/"
done

echo "==> done. Press 'Reload config' in EyesUp Settings to apply without a restart."
