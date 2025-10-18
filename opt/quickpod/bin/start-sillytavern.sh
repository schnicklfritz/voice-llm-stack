#!/usr/bin/env bash
set -Eeuo pipefail

source /opt/quickpod/bin/common.sh
qlog "Starting SillyTavern..."

cd /home/node/app

# Wait for AllTalk to be ready
qlog "Waiting for AllTalk to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:${ALLTALK_PORT:-7851} >/dev/null 2>&1; then
    qlog "AllTalk is ready"
    break
  fi
  sleep 2
done

# Create minimal config if doesn't exist
if [ ! -f config/config.yaml ]; then
  qlog "Creating minimal SillyTavern config..."
  cat > config/config.yaml <<YAML
# Minimal config - user configures Ollama/AllTalk through UI
listen: true
whitelistMode: false
whitelistDockerHosts: true
disableCsrfProtection: true
basicAuthMode: false
YAML
fi

node server.js --listen 2>&1 | tee -a "${LOG_DIR:-/var/log/quickpod}/sillytavern.log" &

qlog "SillyTavern started on port ${ST_PORT:-8000}"
qlog "User will configure Ollama and AllTalk through Extensions UI"
