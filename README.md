# Voice Cloning + Uncensored LLM Stack

Docker Compose stack combining SillyTavern orchestration with Ollama (uncensored LLMs) and AllTalk (voice cloning with RVC).

## Prerequisites

- Docker with nvidia-container-toolkit
- NVIDIA GPU (RTX 4090/5090 recommended)
- At least 32GB VRAM for large models

## Quick Start

1. Clone this repository
2. Copy `.env.example` to `.env` and adjust ports if needed
3. Start the stack: `docker compose up -d`
4. Access SillyTavern at http://localhost:8000

## Configuration

### SillyTavern Backend Connections

- **Ollama**: http://ollama:11434/v1
- **AllTalk**: http://alltalk:7851

### Pull Uncensored Models

docker exec ollama ollama pull dolphin-mistral
docker exec ollama ollama pull wizardlm-uncensored

### Voice Cloning Setup

AllTalk web UI available at http://localhost:7851 for uploading voice samples and configuring RVC.

## Volumes

Data persists in local directories:
- `./sillytavern/` - Characters, chats, settings
- `./ollama/` - Model files
- `./alltalk/` - Voice models, TTS cache

