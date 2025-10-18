#!/usr/bin/env bash
set -euo pipefail

# Load secrets if available
if [ -f /root/.config/secrets.env ]; then
    source /root/.config/secrets.env
    export OPENAI_API_KEY ANTHROPIC_API_KEY HUGGINGFACE_TOKEN
fi

# GPU library paths
export LD_LIBRARY_PATH="/usr/local/lib/ollama:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export PATH="/opt/venv/bin:$PATH"

# Children management
pids=()

cleanup() {
    echo "Entrypoint: cleaning up..."
    for pid in "${pids[@]}"; do
        kill -TERM "$pid" 2>/dev/null || true
    done
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
    exit 0
}

trap 'cleanup' SIGINT SIGTERM EXIT

# GPU diagnostic
echo "════════════════════════════════════════"
echo "GPU Diagnostic:"
ls -la /dev/nvidia* 2>&1 || echo "⚠️  No /dev/nvidia* devices"
nvidia-smi 2>&1 | head -5 || echo "⚠️  nvidia-smi failed"
echo "════════════════════════════════════════"

# Start SSH
service ssh start

# Install SillyTavern
if [ ! -d /workspace/sillytavern ]; then
    git clone --depth 1 https://github.com/SillyTavern/SillyTavern.git -b release /workspace/sillytavern
    cd /workspace/sillytavern && npm install
fi

# Install AllTalk
if [ ! -d /workspace/alltalk_tts ]; then
    python3 -m venv /opt/venv
    /opt/venv/bin/pip install --upgrade pip
    git clone --depth 1 https://github.com/erew123/alltalk_tts.git /workspace/alltalk_tts
    cd /workspace/alltalk_tts
    /opt/venv/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    /opt/venv/bin/pip install gradio pydub librosa soundfile transformers accelerate
fi

# Start services
ollama serve &
pids+=($!)
sleep 5

cd /workspace/alltalk_tts && /opt/venv/bin/python script.py &
pids+=($!)
sleep 2

cd /workspace/sillytavern && node server.js --listen &
pids+=($!)
sleep 1

echo "════════════════════════════════════════"
echo "Voice-LLM Stack Ready!"
echo "SillyTavern: http://POD_IP:8000"
echo "AllTalk TTS: http://POD_IP:7851"
echo "Ollama API:  http://POD_IP:11434"
echo "════════════════════════════════════════"

# Wait for children
while true; do
    wait -n && cleanup
done
