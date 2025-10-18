#!/usr/bin/env bash
set -Eeuo pipefail

source /opt/quickpod/bin/common.sh

qlog "Starting bootstrap..."

# Setup SSH if keys provided
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  qlog "Setting up SSH access..."
  mkdir -p /root/.ssh
  echo "$SSH_PUBLIC_KEY" > /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys
  /usr/sbin/sshd -D &
  qlog "SSH daemon started"
fi

# Install Ollama if not present
if ! command -v ollama &> /dev/null; then
  qlog "Installing Ollama..."
  curl -fsSL https://ollama.ai/install.sh | sh
fi

# Install SillyTavern if not present
if [ ! -d /home/node/app ]; then
  qlog "Installing SillyTavern (first run)..."
  git clone --depth 1 https://github.com/SillyTavern/SillyTavern.git -b release /home/node/app
  cd /home/node/app && npm install --production
  mkdir -p config data plugins public/scripts/extensions/third-party
fi

# Create Python venv if not present
if [ ! -d /opt/venv ]; then
  qlog "Creating Python virtual environment..."
  python3 -m venv /opt/venv
  /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel
fi

# Install AllTalk if not present
if [ ! -d /workspace/alltalk_tts ]; then
  qlog "Installing AllTalk TTS (first run, ~5 min)..."
  git clone --depth 1 https://github.com/erew123/alltalk_tts.git /workspace/alltalk_tts
  cd /workspace/alltalk_tts
  /opt/venv/bin/pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    gradio pydub librosa soundfile transformers accelerate
fi

# Start health check server
bash /opt/quickpod/bin/start-health.sh &

qlog "Bootstrap complete"
