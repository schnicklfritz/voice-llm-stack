#!/usr/bin/env bash
set -Eeuo pipefail

source /opt/quickpod/bin/common.sh
qlog "Starting AllTalk TTS V2..."

cd /workspace/alltalk_tts
source /opt/venv/bin/activate

# Start AllTalk (it will auto-download models on first run)
python script.py 2>&1 | tee -a "${LOG_DIR:-/var/log/quickpod}/alltalk.log" &

sleep 10
qlog "AllTalk TTS V2 started on port ${ALLTALK_PORT:-7851}"
qlog "Note: First run will download Coqui XTTS models (~2GB)"
