#!/usr/bin/env bash
set -Eeuo pipefail

source /opt/quickpod/bin/common.sh
qlog "Starting Ollama server..."

ollama serve 2>&1 | tee -a "${LOG_DIR:-/var/log/quickpod}/ollama.log" &

sleep 5
qlog "Ollama server started on port ${OLLAMA_PORT:-11434}"
