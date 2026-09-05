#!/usr/bin/env bash
# Hour-0 device qualification. Run this once the loaner is in hand.
# Usage: bash scripts/check-device.sh [device-serial]
set -uo pipefail
DEVICE_ARG=""
if [ $# -ge 1 ]; then DEVICE_ARG="-s $1"; fi

echo "=== DEVICE ==="
adb $DEVICE_ARG shell getprop ro.product.model
adb $DEVICE_ARG shell getprop ro.product.manufacturer
adb $DEVICE_ARG shell getprop ro.build.version.release
adb $DEVICE_ARG shell getprop ro.build.version.sdk
adb $DEVICE_ARG shell getprop ro.product.cpu.abi

echo
echo "=== NOTIFICATION LISTENER (is Sarthi enabled?) ==="
adb $DEVICE_ARG shell settings get secure enabled_notification_listeners

echo
echo "=== TTS ENGINES ==="
adb $DEVICE_ARG shell "pm list packages | grep -i -E 'tts|speech'"

echo
echo "=== BATTERY OPTIMISATION (should say the app is exempt) ==="
adb $DEVICE_ARG shell "dumpsys deviceidle whitelist | grep -i sarthi" || echo "  not whitelisted - fix this, see DEVICE_AND_TOOLING_SETUP.md section 4"

echo
echo "=== STORAGE WRITE TEST ==="
adb $DEVICE_ARG shell "mkdir -p /sdcard/Sarthi/config && echo ok > /sdcard/Sarthi/config/.probe && cat /sdcard/Sarthi/config/.probe" \
  || echo "  /sdcard/Sarthi not writable - use the app-private external dir instead"

echo
echo "Paste this output into your PROGRESS.md entry and fill in HANDOFF.md section 5."
