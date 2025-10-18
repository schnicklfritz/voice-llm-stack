import os
import io
import base64
import uuid
import logging
from typing import Optional, List
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from PIL import Image
import torch

# HuggingFace Diffusers
from diffusers import DiffusionPipeline, DPMSolverMultistepScheduler

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("image-api")

app = FastAPI(title="Chroma (lodestones) Image API")

# Environment / defaults
HF_TOKEN = os.environ.get("HF_TOKEN") or os.environ.get("HF_TOKEN", os.environ.get("HF_TOKEN"))
MODEL_ID = os.environ.get("MODEL_ID", "lodestones/Chroma")
DEVICE = os.environ.get("DEVICE", "cuda" if torch.cuda.is_available() else "cpu")
IMAGE_DIR = os.environ.get("IMAGE_DIR", "/app/generated_images")
MAX_BATCH = int(os.environ.get("MAX_BATCH", "1"))

os.makedirs(IMAGE_DIR, exist_ok=True)

logger.info(f"Device set to: {DEVICE}")
logger.info(f"Model id: {MODEL_ID}")

# Load pipeline (defer heavy load until startup)
pipeline: Optional[DiffusionPipeline] = None

@app.on_event("startup")
def load_pipeline():
    global pipeline
    logger.info("Loading Diffusers pipeline for model: %s", MODEL_ID)
    # Use safetensors if available; set torch_dtype to float16 for GPU inference.
    torch_dtype = torch.float16 if DEVICE.startswith("cuda") else torch.float32

    # Use DPMSolverMultistepScheduler for stable sampling (fast + good quality)
    try:
        pipeline = DiffusionPipeline.from_pretrained(
            MODEL_ID,
            torch_dtype=torch_dtype,
            use_safetensors=True,
            local_files_only=False,
            revision=None,
            # pass use_auth_token if present
            use_auth_token=HF_TOKEN or None,
        )
        pipeline.scheduler = DPMSolverMultistepScheduler.from_config(pipeline.scheduler.config)
        if DEVICE.startswith("cuda"):
            pipeline = pipeline.to(DEVICE)
            # enable memory efficient attention if available
            try:
                pipeline.enable_xformers_memory_efficient_attention()
            except Exception:
                pass
        logger.info("Pipeline loaded successfully.")
    except Exception as e:
        logger.exception("Failed to load pipeline: %s", e)
        pipeline = None

class GenRequest(BaseModel):
    prompt: str
    negative_prompt: Optional[str] = ""
    steps: Optional[int] = 20
    guidance_scale: Optional[float] = 7.5
    height: Optional[int] = 512
    width: Optional[int] = 512
    seed: Optional[int] = None
    num_images: Optional[int] = 1

class GenResponse(BaseModel):
    ids: List[str]
    paths: List[str]
    b64: Optional[List[str]] = None

@app.get("/health")
def health():
    ready = pipeline is not None
    return {"status": "ok", "ready": ready, "model": MODEL_ID, "device": DEVICE}

def save_image_and_return_path(img: Image.Image) -> str:
    uid = str(uuid.uuid4())
    path = os.path.join(IMAGE_DIR, f"{uid}.png")
    img.save(path)
    return path, uid

def pil_to_base64(img: Image.Image) -> str:
    buff = io.BytesIO()
    img.save(buff, format="PNG")
    b64 = base64.b64encode(buff.getvalue()).decode("utf-8")
    return b64

@app.post("/generate", response_model=GenResponse)
def generate(req: GenRequest):
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Model pipeline not loaded")

    if req.num_images < 1 or req.num_images > MAX_BATCH:
        raise HTTPException(status_code=400, detail=f"num_images must be 1..{MAX_BATCH}")

    generator = None
    if req.seed is not None:
        gen_device = DEVICE if DEVICE.startswith("cuda") else "cpu"
        generator = torch.Generator(device=gen_device).manual_seed(int(req.seed))

    try:
        logger.info("Generating images for prompt: %s", req.prompt[:120])
        outputs = pipeline(
            req.prompt,
            negative_prompt=req.negative_prompt or None,
            height=req.height,
            width=req.width,
            num_inference_steps=int(req.steps),
            guidance_scale=float(req.guidance_scale),
            num_images_per_prompt=int(req.num_images),
            generator=generator,
        )
    except Exception as e:
        logger.exception("Generation failed")
        raise HTTPException(status_code=500, detail=str(e))

    images = outputs.images if hasattr(outputs, "images") else outputs

    ids = []
    paths = []
    b64s = []
    for img in images:
        path, uid = save_image_and_return_path(img)
        ids.append(uid)
        paths.append(path)
        # optionally return base64 so the client can display inline
        b64s.append(pil_to_base64(img))

    return GenResponse(ids=ids, paths=paths, b64=b64s)
