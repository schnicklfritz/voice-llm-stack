#!/usr/bin/env bash
set -e

# Ensure library paths for GPU
export LD_LIBRARY_PATH="/usr/local/lib/ollama:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export PATH="/opt/venv/bin:$PATH"

# Start SSH
service ssh start

# Install SillyTavern on first run
if [ ! -d /workspace/sillytavern ]; then
    git clone --depth 1 https://github.com/SillyTavern/SillyTavern.git -b release /workspace/sillytavern
    cd /workspace/sillytavern && npm install
fi

# Install AllTalk on first run
if [ ! -d /workspace/alltalk_tts ]; then
    python3 -m venv /opt/venv
    /opt/venv/bin/pip install --upgrade pip
    git clone --depth 1 https://github.com/erew123/alltalk_tts.git /workspace/alltalk_tts
    cd /workspace/alltalk_tts
    /opt/venv/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    /opt/venv/bin/pip install gradio pydub librosa soundfile transformers accelerate
fi

# Start Ollama
ollama serve &
sleep 5

# Start AllTalk
cd /workspace/alltalk_tts && /opt/venv/bin/python script.py &
sleep 5

# Start SillyTavern
cd /workspace/sillytavern && node server.js --listen &

echo "════════════════════════════════════════"
echo "Voice-LLM Stack Ready!"
echo "SillyTavern: http://POD_IP:8000"
echo "AllTalk TTS: http://POD_IP:7851"
echo "Ollama API:  http://POD_IP:11434"
echo ""
echo "Pull a model: ollama pull dolphin-mistral"
echo "════════════════════════════════════════"

# Keep container alive
sleep infinity
