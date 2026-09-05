#!/usr/bin/env bash
# Push the MediaPipe LLM .task model to the device (build-order step 11 only).
# Usage: bash scripts/push-model.sh /path/to/gemma3-1b-it-int4.task [device-serial]
set -euo pipefail

if [ $# -lt 1 ]; then echo "usage: $0 <model.task> [serial]"; exit 1; fi
MODEL="$1"
DEVICE_ARG=""
if [ $# -ge 2 ]; then DEVICE_ARG="-s $2"; fi

if [ ! -f "$MODEL" ]; then echo "!! model not found: $MODEL"; exit 1; fi

# App-private external dir is readable by the app on every API level we target.
# /data/local/tmp/ is NOT readable by a normal app on all ROMs - do not use it.
DEST="/sdcard/Android/data/com.pillion.app/files/llm"

echo "==> size: $(du -h "$MODEL" | cut -f1). This takes about a minute over USB."
adb $DEVICE_ARG shell "mkdir -p $DEST"
adb $DEVICE_ARG push "$MODEL" "$DEST/model.task"
adb $DEVICE_ARG shell "ls -la $DEST"
echo "==> done. LlmParser must load from: $DEST/model.task"
