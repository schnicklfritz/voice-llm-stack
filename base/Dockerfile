# ============================================
# STAGE 1: Base System
# ============================================
FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04 AS base-system

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    software-properties-common wget curl gnupg2 ca-certificates \
    git openssh-server vim htop net-tools netcat-openbsd \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache/*

# Setup SSH
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# ============================================
# STAGE 2: Python + Node Environment
# ============================================
FROM base-system AS runtime-env

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Python 3.12 (default in Ubuntu 24.04)
RUN apt-get update && apt-get install -y \
    python3 python3-venv python3-pip \
    ffmpeg sox libsndfile1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create virtual environment for AllTalk
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# ============================================
# STAGE 3: Application Installation
# ============================================
FROM runtime-env AS apps

# Install Ollama
WORKDIR /workspace
RUN curl -fsSL https://ollama.ai/install.sh | sh

# Install SillyTavern (official structure)
RUN git clone https://github.com/SillyTavern/SillyTavern.git -b release /home/node/app
WORKDIR /home/node/app
RUN npm install \
    && rm -rf /root/.npm /tmp/* /var/tmp/*

# Create SillyTavern directories
RUN mkdir -p /home/node/app/config \
    /home/node/app/data \
    /home/node/app/plugins \
    /home/node/app/public/scripts/extensions/third-party

# Install AllTalk
WORKDIR /workspace
RUN git clone https://github.com/erew123/alltalk_tts.git /workspace/alltalk_tts
WORKDIR /workspace/alltalk_tts

# Install PyTorch first
RUN pip install --no-cache-dir torch torchvision torchaudio

# Install AllTalk requirements (check if requirements.txt exists, if not install core deps)
RUN if [ -f requirements.txt ]; then \
        pip install --no-cache-dir -r requirements.txt; \
    else \
        pip install --no-cache-dir \
            gradio \
            pydub \
            librosa \
            numpy \
            scipy \
            soundfile \
            transformers \
            accelerate \
            TTS; \
    fi && \
    rm -rf /root/.cache/pip /tmp/* /var/tmp/* && \
    find /opt/venv -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# ============================================
# STAGE 4: Final Assembly
# ============================================
FROM apps AS final

# Create directories
RUN mkdir -p /var/log/quickpod /root/.ollama

# Copy QuickPod scripts
COPY opt/quickpod/bin /opt/quickpod/bin
RUN chmod -R +x /opt/quickpod/bin

COPY usr/local/bin/quickpod-entrypoint.sh /usr/local/bin/quickpod-entrypoint.sh
RUN chmod +x /usr/local/bin/quickpod-entrypoint.sh

# Environment
ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 22 8000 11434 7851 8686

ENTRYPOINT ["/usr/local/bin/quickpod-entrypoint.sh"]
