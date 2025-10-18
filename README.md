```markdown
# voice-llm-stack

This repository builds a GPU-ready voice+LLM stack (SillyTavern, AllTalk, Ollama) plus an image generation service (lodestones/Chroma via Diffusers). CI builds container images and pushes them to Docker Hub so you can deploy on QuickPod or any GPU host.

Quick summary of the important files you just added:
- base/Dockerfile — main voice-llm stack image (tini, Ollama, SillyTavern, AllTalk).
- usr/local/bin/quickpod-entrypoint.sh — PID1-friendly signal-aware entrypoint.
- docker-compose.yml — composes voice stack + image-api services.
- docker/image_api.Dockerfile — image generation + Diffusers service.
- services/image_api.py — FastAPI microservice that loads Chroma model via Diffusers.
- requirements.txt — image-api Python deps.
- .github/workflows/build-push.yml — CI pipeline that builds & pushes images.
- scripts/ and rvc/ (optional) — audio extraction/processing helpers (if present).

Before you push
1. Add repository secrets (Settings → Secrets):
   - DOCKERHUB_USERNAME
   - DOCKERHUB_TOKEN
   - HF_TOKEN (if the model requires Hugging Face auth)

2. Add .gitkeep files / create empty directories if they are required by compose:
   - sillytavern/ ollama/ alltalk/ venv/ logs/ image_store/ models/ chroma_data/

3. Update docker-compose.yml or QuickPod template with the image names you want to deploy (the workflow tags images as `<DOCKERHUB_USERNAME>/quickpod-voice-llm:latest` and `<DOCKERHUB_USERNAME>/image-api:latest`).

How to push & deploy
- Commit and push to main (or trigger workflow_dispatch). The Actions workflow will build and push both images to Docker Hub.
- On QuickPod, point your pod to the pushed image (use :latest or the SHA tag shown in Actions).
- Deploy with `--gpus all` and verify with the health endpoints:
  - Voice stack: http://<POD_IP>:8000 (SillyTavern), Ollama API at :11434
  - Image API: http://<POD_IP>:9000/health ; generate at POST /generate

Notes and troubleshooting
- CI cannot run GPU tests; validate GPU behavior on QuickPod after deployment.
- If images are large, ensure your Docker Hub account has enough storage or split images into smaller pieces.
- If Diffusers model requires HF_TOKEN, set it as a secret and as an environment variable for the QuickPod container.

License
This repo uses the MIT license (see LICENSE).

If you want, I can:
- add a one-file Gradio UI that connects to the voice and image endpoints,
- add the .github/workflows job that publishes the image-api image (if you'd like separate control),
- or produce a small QuickPod deployment template (the exact fields your QuickPod UI needs).
```
