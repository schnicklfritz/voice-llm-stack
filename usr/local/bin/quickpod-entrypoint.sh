#!/usr/bin/env bash
set +e  # Don't exit on errors - critical for debugging

mkdir -p /var/log/quickpod /workspace/loras

# GPU Environment
export LD_LIBRARY_PATH="/usr/lib/ollama:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export CUTLASS_PATH="/workspace/cutlass"
export TORCH_CUDA_ARCH_LIST="8.6"
export OLLAMA_SCHED_SPREAD=1
export CUDA_HOME="/usr/local/cuda"

# Download Z-Image-Turbo GGUF if missing
GGUF_PATH="/workspace/z-image-turbo-Q8_0.gguf"
if [ ! -f "$GGUF_PATH" ]; then
    echo "Downloading Z-Image-Turbo GGUF (~7.5GB)..."
    wget -q --show-progress \
        https://huggingface.co/city96/Z-Image-Turbo-GGUF/resolve/main/z-image-turbo-Q8_0.gguf \
        -O "$GGUF_PATH" || echo "⚠ Download failed, image API won't start"
fi

# Start services
echo "Starting Ollama..."
touch /var/log/quickpod/ollama.log
/usr/bin/ollama serve > /var/log/quickpod/ollama.log 2>&1 &

echo "Starting SillyTavern..."
touch /var/log/quickpod/st.log
cd /workspace/SillyTavern && node server.js --listen > /var/log/quickpod/st.log 2>&1 &

# Start Image API only if GGUF exists
if [ -f "$GGUF_PATH" ] && [ -x /opt/image_api_venv/bin/uvicorn ]; then
    echo "Starting Z-Image-Turbo API..."
    touch /var/log/quickpod/image.log
    cd /workspace
    /opt/image_api_venv/bin/uvicorn services.image_api:app \
        --host 0.0.0.0 --port 9000 \
        > /var/log/quickpod/image.log 2>&1 &
else
    echo "⚠ Z-Image-Turbo API skipped (GGUF missing or venv not ready)"
fi

echo "════════════════════════════════════════"
echo "✓ Container ready - Connect via QuickPod SSH"
echo "Manual: cd /workspace/alltalk_v2 && ./atsetup.sh"
echo "Logs: /var/log/quickpod/"
echo "════════════════════════════════════════"

# Keep container alive
exec tail -f /dev/null
