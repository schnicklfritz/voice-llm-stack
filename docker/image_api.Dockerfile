FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ffmpeg libsndfile1 curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy service files
COPY services /app/services
COPY requirements.txt /app/requirements.txt

# Setup virtualenv and install core deps
RUN python -m venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip setuptools wheel

# Try to install CUDA 13 / cu130 PyTorch wheel (best-effort).
# If the wheel isn't compatible on the CI builder, pip will continue and CPU fallback may be used on build hosts.
RUN pip install --index-url https://download.pytorch.org/whl/cu130 "torch" "torchvision" "torchaudio" || true

# Install python requirements (diffusers, transformers, accelerate, etc.)
RUN pip install --no-cache-dir -r /app/requirements.txt

# Create image dir
RUN mkdir -p /app/generated_images
VOLUME ["/app/generated_images"]

EXPOSE 9000

CMD ["uvicorn", "services.image_api:app", "--host", "0.0.0.0", "--port", "9000", "--workers", "1"]
