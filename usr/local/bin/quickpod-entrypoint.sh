#!/usr/bin/env bash
set -euo pipefail

# 0. ensure log dir
mkdir -p /var/run/sshd /var/log/quickpod

# 1. GPU & Compilation Environment (Correctly additive)
export LD_LIBRARY_PATH="/usr/lib/ollama:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export CUTLASS_PATH="/workspace/cutlass"
export TORCH_CUDA_ARCH_LIST="8.6"
export OLLAMA_SCHED_SPREAD=1
export CUDA_HOME="/usr/local/cuda"

# 2. Ensure SSH host keys exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  ssh-keygen -A
fi

# 3. QuickPod Connectivity Fix (heartbeat)
# Run in background so it doesn't block startup
while true; do ( echo -ne "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" ) | nc -lk -p 8686; done &

# 4. Start sshd reliably (log to quickpod log)
# Start sshd in daemon mode so it forks and we can continue starting other services.
# If you prefer to keep it foreground for debugging, run: /usr/sbin/sshd -D -e
/usr/sbin/sshd -E /var/log/quickpod/sshd.log &

# 5. Start other services (backgrounded) and make sure logs exist
touch /var/log/quickpod/ollama.log /var/log/quickpod/st.log /var/log/quickpod/image.log
ollama serve > /var/log/quickpod/ollama.log 2>&1 &
cd /workspace/SillyTavern && node server.js --listen > /var/log/quickpod/st.log 2>&1 &
if [ -x /opt/image_api_venv/bin/uvicorn ]; then
  /opt/image_api_venv/bin/uvicorn /workspace/image_api:app --host 0.0.0.0 --port 9000 > /var/log/quickpod/image.log 2>&1 &
fi

# 6. Helpful status and next steps message
echo "════════════════════════════════════════"
echo "READY: Terminal access restored (if sshd started)."
echo "Manual Step: cd /workspace/alltalk_v2 && ./atsetup.sh"
echo "Logs: /var/log/quickpod/*"
echo "════════════════════════════════════════"

# 7. Follow logs so container stays alive and so you can see sshd errors
exec tail -F /var/log/quickpod/*.log
