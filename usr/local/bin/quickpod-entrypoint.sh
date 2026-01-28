#!/usr/bin/env bash
set -uo pipefail 

# 1. GPU & Compilation Environment (Correctly additive)
# Restore the paths you need for DeepSpeed JIT without breaking the OS
export LD_LIBRARY_PATH="/usr/lib/ollama:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export CUTLASS_PATH="/workspace/cutlass" export TORCH_CUDA_ARCH_LIST="8.6"   # Native for RTX 3090 (Ampere) [web:144]
export OLLAMA_SCHED_SPREAD=1      # Multi-GPU Load Balancing
export CUDA_HOME="/usr/local/cuda" # Critical for AllTalk JIT [web:24]

# 2. QuickPod Connectivity Fix
# Port 8686 is the 'heartbeat' for the QuickPod Web Terminal
# Corrected: Strict CRLF (\r\n) for HTTP/1.1 compliance
while true; do ( echo -ne "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" ) | nc -lk -p 8686; done &


# 3. Services Start
service ssh start
ollama serve > /var/log/quickpod/ollama.log 2>&1 &
cd /workspace/SillyTavern && node server.js --listen > /var/log/quickpod/st.log 2>&1 &
/opt/image_api_venv/bin/uvicorn /workspace/image_api:app --host 0.0.0.0 --port 9000 > /var/log/quickpod/image.log 2>&1 &

# 4. Manual Setup Note
echo "════════════════════════════════════════"
echo "READY: Terminal access restored (100/100)."
echo "Manual Step: cd /workspace/alltalk_v2 && ./atsetup.sh"
echo "Env: CUTLASS_PATH and ARCH_LIST are active."
echo "════════════════════════════════════════"

tail -f /dev/null
