#!/bin/bash

# Start script for ComfyUI + LTX 2.3 on RunPod
# This script starts ComfyUI with API enabled and optimized settings for RTX 4090

echo "=========================================="
echo "Starting ComfyUI + LTX 2.3 Creative Universe Engine"
echo "=========================================="
echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'No GPU detected')"
echo "Python Version: $(python --version)"
echo "=========================================="

# Set environment variables for optimization
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_LAUNCH_BLOCKING=0
export TF_CPP_MIN_LOG_LEVEL=3

# Check if models directory exists, create if not
if [ ! -d "/app/comfyui/models/checkpoints" ]; then
    echo "Creating models directory structure..."
    mkdir -p /app/comfyui/models/{checkpoints,loras,vae,upscale_models,controlnet}
fi

# Check for LTX 2.3 models
echo "Checking for LTX 2.3 models..."
if [ ! -f "/app/comfyui/models/checkpoints/ltx-2.3-22b-distilled-1.1.safetensors" ]; then
    echo "WARNING: LTX 2.3 model not found in /app/comfyui/models/checkpoints/"
    echo "You need to download the model from HuggingFace:"
    echo "  - ltx-2.3-22b-distilled-1.1.safetensors"
    echo "  - ltx-2.3-spatial-upscaler-x2-1.1.safetensors"
    echo "Place them in /app/comfyui/models/checkpoints/"
    echo ""
    echo "For testing, ComfyUI will still start but LTX video generation will fail."
fi

# Start ComfyUI with API enabled
echo "Starting ComfyUI server on 0.0.0.0:8188..."
cd /app/comfyui

python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --enable-cors-header \
    --disable-auto-launch \
    --highvram \
    --disable-metadata

# Note: --highvram is used for RTX 4090 with 24GB VRAM
# For lower VRAM GPUs, change to --normalvram or --lowvram
