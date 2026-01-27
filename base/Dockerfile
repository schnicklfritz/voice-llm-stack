FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    LD_LIBRARY_PATH="/usr/lib/ollama:/usr/lib/x86_64-linux-gnu" \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    CUDA_VISIBLE_DEVICES=0,1

# 1. System Dependencies (Optimized for 24.04 and AllTalk v2)
RUN apt-get update && apt-get install -y \
    netcat-openbsd wget curl git bzip2 xz-utils ca-certificates \
    openssh-server nano htop net-tools \
    nodejs npm python3 python3-venv python3-dev \
    ffmpeg sox libsndfile1 build-essential tini \
    && mkdir -p /var/run/sshd /root/.ollama /workspace /var/log/quickpod \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Ollama Installation (Fixed Path)
RUN curl -L https://github.com/ollama/ollama/releases/download/v0.5.4/ollama-linux-amd64.tgz -o /tmp/ollama.tgz && \
    tar -xzf /tmp/ollama.tgz -C /usr && \
    rm /tmp/ollama.tgz

# 3. AllTalk v2 Source Prep (Ready for manual ./atsetup.sh)
RUN git clone https://github.com/erew123/alltalk_tts /workspace/alltalk_v2 \
    && chmod +x /workspace/alltalk_v2/*.sh

# 4. SillyTavern Hydration (Fallback UI)
RUN git clone https://github.com/SillyTavern/SillyTavern /workspace/SillyTavern

# STEP 5: Consolidated SD 1.5 Image-API Environment
# We explicitly install CUDA-accelerated PyTorch for the 3090s
WORKDIR /workspace
COPY requirements.txt /workspace/requirements.txt
COPY services /workspace/services

RUN python3 -m venv /opt/image_api_venv \
    && /opt/image_api_venv/bin/pip install --upgrade pip setuptools wheel \
    && /opt/image_api_venv/bin/pip install --index-url https://download.pytorch.org/whl/cu124 torch torchvision torchaudio \
    && /opt/image_api_venv/bin/pip install --no-cache-dir -r /workspace/requirements.txt \
    && /opt/image_api_venv/bin/pip install xformers>=0.0.22 


# 6: DeepSpeed & CUTLASS Optimization (For 3090 Ampere Support)
# We clone CUTLASS to a fixed location and set the environment path for DeepSpeed
RUN git clone --recursive https://github.com/NVIDIA/cutlass /workspace/cutlass
ENV CUTLASS_PATH=/workspace/cutlass \
    TORCH_CUDA_ARCH_LIST="8.6" \
    DS_BUILD_OPS=1 \
    DS_BUILD_SPARSE_ATTN=1

# Install libaio-dev which is a hard dependency for DeepSpeed's async_io
RUN apt-get update && apt-get install -y libaio-dev && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set build-time variables for DeepSpeed to target your 3090s (Compute 8.6)
# This speeds up the JIT compilation during your manual ./atsetup.sh
ENV TORCH_CUDA_ARCH_LIST="8.6" \
    DS_BUILD_OPS=1 \
    DS_BUILD_SPARSE_ATTN=1



# Entrypoint setup
COPY usr/local/bin/quickpod-entrypoint.sh /usr/local/bin/quickpod-entrypoint.sh
RUN chmod +x /usr/local/bin/quickpod-entrypoint.sh

EXPOSE 22 8686 8000 11434 7851 7852 7052 9000
ENTRYPOINT ["/usr/local/bin/quickpod-entrypoint.sh"]
