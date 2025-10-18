FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/opt/venv/bin:$PATH" \
    LD_LIBRARY_PATH="/usr/local/lib/ollama:/usr/lib/x86_64-linux-gnu" \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    CUDA_VISIBLE_DEVICES=0

# NOTE: Do NOT bake secrets into the image. Remove any build-time secret embedding.
RUN apt-get update && apt-get install -y \
    wget curl git \
    openssh-server vim htop net-tools netcat-openbsd \
    nodejs npm \
    python3 python3-venv python3-pip \
    ffmpeg sox libsndfile1 \
    tini \
    && mkdir -p /var/run/sshd /root/.ollama /workspace /var/log/quickpod \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install official Ollama with GPU support
RUN curl -L https://github.com/ollama/ollama/releases/download/v0.5.4/ollama-linux-amd64.tgz -o /tmp/ollama.tgz && \
    tar -xzf /tmp/ollama.tgz -C /usr/local && \
    rm /tmp/ollama.tgz

# Copy entrypoint (entrypoint will read runtime env vars if present)
COPY usr/local/bin/quickpod-entrypoint.sh /usr/local/bin/quickpod-entrypoint.sh
RUN chmod +x /usr/local/bin/quickpod-entrypoint.sh

EXPOSE 22 8000 11434 7851 8686

ENTRYPOINT ["/usr/local/bin/quickpod-entrypoint.sh"]
