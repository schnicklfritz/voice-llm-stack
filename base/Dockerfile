FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/opt/venv/bin:$PATH"

# Install only system packages (no downloads)
RUN apt-get update && apt-get install -y \
    wget curl git \
    openssh-server vim htop net-tools netcat-openbsd \
    nodejs npm \
    python3 python3-venv python3-pip \
    ffmpeg sox libsndfile1 \
    && mkdir -p /var/run/sshd /var/log/quickpod /root/.ollama \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy scripts only (tiny)
COPY opt/quickpod/bin /opt/quickpod/bin
COPY usr/local/bin/quickpod-entrypoint.sh /usr/local/bin/quickpod-entrypoint.sh
RUN chmod -R +x /opt/quickpod/bin /usr/local/bin/quickpod-entrypoint.sh

EXPOSE 22 8000 11434 7851 8686

ENTRYPOINT ["/usr/local/bin/quickpod-entrypoint.sh"]
