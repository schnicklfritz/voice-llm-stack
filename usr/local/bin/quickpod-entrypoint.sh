#!/usr/bin/env bash
set -euo pipefail

# Ensure LD_LIBRARY_PATH includes common GPU libs
export LD_LIBRARY_PATH="/usr/local/lib/ollama:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export PATH="/opt/venv/bin:$PATH"

pids=()

sigterm_handler() {
    echo "Entrypoint: received SIGTERM/SIGINT, shutting down children..."
    for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    # give them time to shut down
    sleep 3

    # force kill any remaining
    for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done

    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || true
    done

    exit 0
}

trap 'sigterm_handler' SIGINT SIGTERM

# Start SSH
service ssh start

# First-run installs
if [ ! -d /workspace/sillytavern ]; then
    git clone --depth 1 https://github.com/SillyTavern/SillyTavern.git -b release /workspace/sillytavern
    cd /workspace/sillytavern && npm install
fi

if [ ! -d /workspace/alltalk_tts ]; then
    python3 -m venv /opt/venv
    /opt/venv/bin/pip install --upgrade pip
    git clone --depth 1 https://github.com/erew123/alltalk_tts.git /workspace/alltalk_tts
    cd /workspace/alltalk_tts
    /opt/venv/bin/pip install -r requirements.txt || true
fi

# Start Ollama
ollama serve &
pids+=($!)
sleep 2

# Start AllTalk
cd /workspace/alltalk_tts && /opt/venv/bin/python script.py &
pids+=($!)
sleep 2

# Start SillyTavern
cd /workspace/sillytavern && node server.js --listen &
pids+=($!)
sleep 1

echo "════════════════════════════════════════"
echo "Voice-LLM Stack Ready!"
echo "SillyTavern: http://POD_IP:8000"
echo "AllTalk TTS: http://POD_IP:7851"
echo "Ollama API:  http://POD_IP:11434"
echo ""
echo "Pull a model: ollama pull dolphin-mistral"
echo "════════════════════════════════════════"

# Wait for any child to exit (so failures are visible); cleanup via trap
while true; do
    if wait -n; then
        echo "A child process exited, shutting down container."
        sigterm_handler
    fi
done
