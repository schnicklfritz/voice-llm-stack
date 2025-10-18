# Voice-LLM Stack for QuickPod

Complete AI chat stack with voice cloning in a single Docker container. Built for QuickPod GPU instances.

**Stack:**
- **SillyTavern** - Advanced chat interface with character cards and extensions
- **Ollama** - Local LLM inference (uncensored models supported)
- **AllTalk TTS V2** - Voice cloning and text-to-speech (Coqui XTTS, F5-TTS, Piper)

**Image:** `schnicklbob/quickpod-voice-llm:latest`

**Size:** ~8-10GB compressed

---

## 🚀 Quick Start on QuickPod

### 1. Deploy Pod

1. Go to [QuickPod Console](https://console.quickpod.io/)
2. **GPU:** RTX 3060 (12GB) minimum, RTX 4090 (24GB) recommended
3. **Template:** Custom Docker Image
4. **Image:** `schnicklbob/quickpod-voice-llm:latest`
5. **Ports:** Map `22, 8000, 11434, 7851, 8686`
6. **Storage:** 100GB minimum
7. **(Optional)** Add environment variable:
   - `SSH_PUBLIC_KEY=<your-ssh-public-key>` for SSH access
8. Click **Deploy**

### 2. Access Services

Once deployed, QuickPod will show your pod's public IP. Access:

- **SillyTavern:** `http://<pod-ip>:8000` (Main chat interface)
- **AllTalk:** `http://<pod-ip>:7851` (Voice cloning UI)
- **Ollama API:** `http://<pod-ip>:11434` (Direct LLM API)
- **Health Check:** `http://<pod-ip>:8686` (Status endpoint)

---

## 📥 Pull LLM Models

SSH into your pod or use `docker exec`:

Connect to container

docker exec -it voice-llm-stack bash
Small test models (3-5GB each)

ollama pull phi-2
ollama pull tinyllama
Uncensored models (7-13GB each)

ollama pull dolphin-mistral:latest
ollama pull wizardlm2:7b
ollama pull nous-hermes2:10.7b-solar-q6_K
Code models

ollama pull deepseek-coder:6.7b
Large models (24GB+ VRAM required)

ollama pull wizardlm-uncensored:13b
ollama pull nous-hermes-2-mixtral:8x7b
List installed models

ollama list


---

## ⚙️ Configure in SillyTavern

Access SillyTavern at `http://<pod-ip>:8000`

### Connect to Ollama

1. Click **Settings** (gear icon, top-right)
2. Go to **API Connections** tab
3. Select **Chat Completion** API
4. Set **Chat Completion Source** to **Ollama**
5. **API URL:** `http://localhost:11434`
6. Click **Connect**
7. Select your pulled model from the dropdown

### Enable AllTalk TTS

1. Go to **Extensions** tab (puzzle piece icon)
2. Click **TTS** section
3. **Provider:** Select **AllTalk**
4. **Provider Endpoint:** `http://localhost:7851`
5. Click **Connect**
6. Test with "Generate" button

---

## 🎤 Voice Cloning with AllTalk

Access AllTalk at `http://<pod-ip>:7851`

### Create Custom Voice

1. Record 6-10 seconds of clear audio (WAV or MP3)
   - Single speaker
   - Minimal background noise
   - Normal speaking pace
2. Upload via **Voice Cloning** tab in AllTalk UI
3. Give it a name (e.g., `my_voice`)
4. Click **Process** or **Clone Voice**
5. Wait 30-60 seconds for processing

### Use Cloned Voice in SillyTavern

1. In SillyTavern: **Extensions** → **TTS**
2. **Voice** dropdown will now show your cloned voice
3. Select it for your character
4. Enable TTS in character settings
5. Character now speaks with your cloned voice!

**Per-Character Voices:**
- Upload multiple voice samples to AllTalk
- Assign different voices to different characters
- Mix male/female/character voices as needed

---

## 📁 Volume Structure

Data persists in these directories:

voice-llm-stack/
├── sillytavern/
│ ├── config/ # SillyTavern settings
│ └── data/ # Characters, chats, user data
├── ollama/ # Downloaded LLM models
├── alltalk/ # Voice models and clones
└── logs/ # Service logs


Mount these if deploying with `docker-compose` for persistence.

---

## 🔧 Advanced Configuration

### SillyTavern Config

Edit `/home/node/app/config/config.yaml` inside container:

Enable authentication

basicAuthMode: true
basicAuthUser:
username: "your-username"
password: "your-password"
Enable IP whitelist

whitelistMode: true
whitelist:

    "your.ip.address"


Restart container after changes:

docker restart voice-llm-stack


### Environment Variables

Override defaults in QuickPod template:

- `ST_PORT=8000` - SillyTavern port
- `OLLAMA_PORT=11434` - Ollama API port
- `ALLTALK_PORT=7851` - AllTalk port
- `HEALTH_PORT=8686` - Health check port
- `SSH_PUBLIC_KEY=<key>` - Enable SSH access

---

## 🐛 Troubleshooting

### AllTalk not responding

**First run downloads models (~2GB):**

Check logs

docker logs voice-llm-stack | grep alltalk
Wait for download to complete
Access http://<pod-ip>:7851 once ready


### Ollama connection failed

**Ensure models are pulled:**

docker exec voice-llm-stack ollama list

**Check Ollama is running:**

docker exec voice-llm-stack ps aux | grep ollama


**Test API directly:**

curl http://<pod-ip>:11434/api/tags

### SillyTavern whitelist error

Default config has `whitelistMode: false`. If you enabled it manually:

docker exec voice-llm-stack vim /home/node/app/config/config.yaml
Add your IP to whitelist array

docker restart voice-llm-stack

### Out of VRAM

**Symptoms:** Models crash, OOM errors in logs

**Solutions:**
- Use smaller models (7B instead of 13B)
- Enable AllTalk **Low VRAM Mode** in settings
- Don't run multiple large models simultaneously
- Use quantized models (Q4, Q5 variants)

### SSH not working

Ensure you set `SSH_PUBLIC_KEY` environment variable when deploying:

Check if SSH is running

docker exec voice-llm-stack ps aux | grep sshd
Add key manually

docker exec -it voice-llm-stack bash
mkdir -p /root/.ssh
echo "<your-public-key>" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

---

## 💻 Local Development

### Test with Docker Compose

http://localhost:8000/
git clone https://github.com/Schnicklfritz/voice-llm-stack.git
cd voice-llm-stack
docker compose up -d
Access locally
SillyTavern: http://localhost:8000
AllTalk: http://localhost:7851
Ollama: http://localhost:11434

### Build Locally

docker build -f base/Dockerfile -t voice-llm-stack:dev .

### View Logs

docker logs -f voice-llm-stack
Or specific service

docker exec voice-llm-stack tail -f /var/log/quickpod/sillytavern.log
docker exec voice-llm-stack tail -f /var/log/quickpod/ollama.log
docker exec voice-llm-stack tail -f /var/log/quickpod/alltalk.log

---

## 📊 Recommended Hardware

| Use Case | GPU | VRAM | Models Supported |
|----------|-----|------|------------------|
| **Testing** | RTX 3060 | 12GB | Small models (phi-2, tinyllama, 7B quantized) |
| **Standard** | RTX 4070 Ti | 16GB | 7B models, voice cloning |
| **Recommended** | RTX 4090 | 24GB | 13B models, multiple simultaneous |
| **Production** | 2x RTX 4090 | 48GB | Mixtral 8x7B, long conversations |

**AllTalk Requirements:**
- Minimum 4GB VRAM for Coqui XTTS
- 8GB+ recommended for voice cloning
- F5-TTS mode: 2GB VRAM (faster, lower quality)

---

## 🔗 Documentation

- **SillyTavern Docs:** https://docs.sillytavern.app
- **AllTalk Wiki:** https://github.com/erew123/alltalk_tts/wiki
- **Ollama Models:** https://ollama.ai/library
- **QuickPod Support:** https://discord.gg/quickpod

---

## 📝 License

This repository configuration is MIT licensed. Individual components have their own licenses:
- SillyTavern: AGPL-3.0
- Ollama: MIT
- AllTalk: Apache-2.0

---

## 🙏 Credits

Built with:
- [SillyTavern](https://github.com/SillyTavern/SillyTavern) by SillyTavern Team
- [Ollama](https://ollama.ai) by Ollama Team
- [AllTalk TTS](https://github.com/erew123/alltalk_tts) by erew123
- Inspired by QuickPod's official container templates

---

## 🆘 Support

**Issues with this container:**
- GitHub Issues: https://github.com/Schnicklfritz/voice-llm-stack/issues

**Component-specific issues:**
- SillyTavern: https://github.com/SillyTavern/SillyTavern/issues
- AllTalk: https://github.com/erew123/alltalk_tts/issues
- Ollama: https://github.com/ollama/ollama/issues
EOF

git add README.md
git commit -m "Add comprehensive README"
git push origin main


