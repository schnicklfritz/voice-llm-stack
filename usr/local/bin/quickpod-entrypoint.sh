#!/usr/bin/env bash
set -euo pipefail

# 1. Environment & GPU Paths (Updated for Ollama v0.15.2)
export LD_LIBRARY_PATH="/usr/lib/ollama:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export CUTLASS_PATH="/workspace/cutlass"
export TORCH_CUDA_ARCH_LIST="8.6"
export OLLAMA_SCHED_SPREAD=1 # Balanced Dolphin 20B across dual 3090s [web:148]

pids=()

cleanup() {
    echo "Entrypoint: cleaning up..."
    for pid in "${pids[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
    exit 0
}
trap 'cleanup' SIGINT SIGTERM EXIT

# 2. Services Start
service ssh start

# QuickPod Health Check (MANDATORY for WebUI) [web:198]
while true; do nc -l -p 8686 -e /bin/echo "ok" >/dev/null 2>&1; done &
pids+=($!)

# Ollama v0.15.2 (Dolphin 20B ready)
ollama serve > /var/log/quickpod/ollama.log 2>&1 &
pids+=($!)

# SillyTavern (Using the path from Dockerfile)
cd /workspace/SillyTavern && node server.js --listen > /var/log/quickpod/st.log 2>&1 &
pids+=($!)

# SD 1.5 Image API (The new lightweight service) [web:108]
/opt/image_api_venv/bin/uvicorn /workspace/image_api:app --host 0.0.0.0 --port 9000 > /var/log/quickpod/image.log 2>&1 &
pids+=($!)

# 3. AllTalk v2 Manual Note
echo "════════════════════════════════════════"
echo "Stack is booting. AllTalk v2 is ready for MANUAL setup."
echo "SSH in and run: cd /workspace/alltalk_v2 && ./atsetup.sh"
echo "════════════════════════════════════════"

# Keep container alive
while true; do
    wait -n || true
done
