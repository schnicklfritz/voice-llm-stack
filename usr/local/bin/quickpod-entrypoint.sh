#!/usr/bin/env bash
set -Eeuo pipefail

: "${LOG_DIR:=/var/log/quickpod}"
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/boot.log" "$LOG_DIR/sillytavern.log" "$LOG_DIR/ollama.log" "$LOG_DIR/alltalk.log"
chmod 644 "$LOG_DIR"/*.log || true

ln -sf /proc/1/fd/1 "$LOG_DIR/boot.stdout" || true
ln -sf /proc/1/fd/2 "$LOG_DIR/boot.stderr" || true

export PATH="/opt/venv/bin:$PATH"

bash /opt/quickpod/bin/bootstrap.sh

# Start services in correct order
bash /opt/quickpod/bin/start-ollama.sh
bash /opt/quickpod/bin/start-alltalk.sh
sleep 5
bash /opt/quickpod/bin/start-sillytavern.sh

source /opt/quickpod/bin/common.sh
ST_EXT="$(public_url "${ST_PORT:-8000}" http)"
OLLAMA_EXT="$(public_url "${OLLAMA_PORT:-11434}" http)"
ALLTALK_EXT="$(public_url "${ALLTALK_PORT:-7851}" http)"
HEALTH_EXT="$(public_url "${HEALTH_PORT:-8686}" http)"

qlog "════════ QuickPod Voice-LLM Stack ═════════"
qlog "SillyTavern:      ${ST_EXT}"
qlog "  > Configure Ollama: Settings > API Connections > Ollama"
qlog "  > API URL: http://localhost:11434"
qlog "  > Configure TTS: Extensions > TTS > AllTalk"
qlog "  > API URL: http://localhost:7851"
qlog ""
qlog "Ollama API:       ${OLLAMA_EXT}"
qlog "  > Pull models: docker exec <container> ollama pull dolphin-mistral"
qlog ""
qlog "AllTalk TTS:      ${ALLTALK_EXT}"
qlog "  > Web UI for voice cloning"
qlog ""
qlog "Health Check:     ${HEALTH_EXT}"
qlog "Public IP:        ${PUBLIC_IPADDR:-unknown}"
qlog "GPUs (requested): ${GPU_COUNT:-unknown}"
qlog "Pod Label:        ${CONTAINER_LABEL:-n/a}"
qlog "SSH PubKey:       $([ -n "${SSH_PUBLIC_KEY:-}" ] && echo yes || echo no)"
qlog "════════════════════════════════════════════"

tail -n 200 -F "$LOG_DIR"/*.log 2>/dev/null
