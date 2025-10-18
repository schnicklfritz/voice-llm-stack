# Managing Secrets

## GitHub Repository Secrets

Add these secrets to your GitHub repository:
Settings → Secrets and variables → Actions → New repository secret

### Required Secrets
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Docker Hub access token

### Optional API Keys
- `OPENAI_API_KEY`: OpenAI API key for GPT models
- `ANTHROPIC_API_KEY`: Anthropic API key for Claude models
- `HUGGINGFACE_TOKEN`: Hugging Face token for model downloads

## Runtime Access

Secrets are available inside the container at:

source /root/.config/secrets.env
echo $OPENAI_API_KEY

## Local Development

Create `.env` file (gitignored):

cp env.example .env
Edit .env with your local keys
