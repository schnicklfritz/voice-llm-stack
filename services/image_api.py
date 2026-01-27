import os
import io
import re
import torch
import base64
from fastapi import FastAPI
from pydantic import BaseModel
from diffusers import ZImagePipeline, ZImageTransformer2DModel, GGUFQuantizationConfig

app = FastAPI()

# Configuration
MODEL_ID = "Tongyi-MAI/Z-Image-Turbo"
GGUF_PATH = "/workspace/z-image-turbo-Q8_0.gguf"
LORA_DIR = "/workspace/loras"

# Global pipeline and tracking
pipe = None
LOADED_LORAS = set()

@app.on_event("startup")
def load_zit():
    global pipe
    os.makedirs(LORA_DIR, exist_ok=True)
    
    transformer = ZImageTransformer2DModel.from_single_file(
        GGUF_PATH,
        quantization_config=GGUFQuantizationConfig(compute_dtype=torch.bfloat16),
        torch_dtype=torch.bfloat16,
    )
    
    pipe = ZImagePipeline.from_pretrained(
        MODEL_ID, 
        transformer=transformer, 
        torch_dtype=torch.bfloat16
    ).to("cuda")
    
    pipe.enable_model_cpu_offload()

class ExtrasRequest(BaseModel):
    prompt: str
    seed: int = -1

@app.post("/api/image")
def st_extras_mimic(req: ExtrasRequest):
    global LOADED_LORAS
    prompt = req.prompt
    seed = torch.seed() if req.seed == -1 else req.seed
    generator = torch.Generator("cuda").manual_seed(seed)
    
    # 1. Reset active adapters for this specific generation
    pipe.set_adapters([])
    
    # 2. Find all LoRA tags: <lora:filename:weight>
    lora_matches = re.findall(r"<lora:([^:]+):?([\d.]+)*>", prompt)
    active_names = []
    active_weights = []
    
    for match in lora_matches:
        lora_name = match[0]
        lora_weight = float(match[1]) if match[1] else 1.0
        lora_path = os.path.join(LORA_DIR, f"{lora_name}.safetensors")
        
        if os.path.exists(lora_path):
            # Only load from disk if not already in VRAM
            if lora_name not in LOADED_LORAS:
                pipe.load_lora_weights(lora_path, adapter_name=lora_name)
                LOADED_LORAS.add(lora_name)
                print(f"Loaded new LoRA to VRAM: {lora_name}")
            
            active_names.append(lora_name)
            active_weights.append(lora_weight)
            
            # Clean prompt of the tag
            prompt = prompt.replace(f"<lora:{match[0]}:{match[1]}>" if match[1] else f"<lora:{match[0]}>", "")

    # 3. Apply the persistent adapters
    if active_names:
        pipe.set_adapters(active_names, adapter_weights=active_weights)

    # 4. Generate with Z-Image Turbo settings
    image = pipe(
        prompt=prompt.strip(), 
        num_inference_steps=9, 
        guidance_scale=0.0, 
        generator=generator
    ).images[0]
    
    # Base64 conversion for SillyTavern
    buffered = io.BytesIO()
    image.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
    
    return {"image": img_str}
