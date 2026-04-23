# ============================================================
# ComfyUI + LTX Video Dockerfile for RunPod
# Creative Universe Engine — GPU-accelerated video generation
# ============================================================
# This Dockerfile creates a container with:
# 1. ComfyUI (latest) with API enabled
# 2. ComfyUI-LTXVideo custom nodes (Lightricks official)
# 3. All required Python dependencies
# 4. Optimized for RTX 4090 (24GB VRAM) on RunPod
# ============================================================

# Base image with CUDA 12.1 and Python 3.11
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic links for python
RUN ln -sf /usr/bin/python3.11 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.11 /usr/bin/python

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

# Create working directory
WORKDIR /app

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/comfyui

# Install ComfyUI Python dependencies (PyTorch with CUDA 12.1)
WORKDIR /app/comfyui
RUN python3 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
RUN python3 -m pip install -r requirements.txt

# Clone and install ComfyUI-LTXVideo custom nodes (official Lightricks integration)
RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git /app/comfyui/custom_nodes/ComfyUI-LTXVideo
WORKDIR /app/comfyui/custom_nodes/ComfyUI-LTXVideo
RUN python3 -m pip install -r requirements.txt

# Install additional dependencies for video generation
RUN python3 -m pip install \
    transformers \
    safetensors \
    accelerate \
    diffusers \
    einops \
    scipy \
    pillow \
    imageio \
    imageio-ffmpeg \
    opencv-python-headless

# Create models directory structure
RUN mkdir -p /app/comfyui/models/checkpoints \
    /app/comfyui/models/loras \
    /app/comfyui/models/vae \
    /app/comfyui/models/upscale_models \
    /app/comfyui/models/controlnet \
    /app/comfyui/input \
    /app/comfyui/output

# Copy startup script
COPY --chmod=755 start.sh /app/start.sh

# Expose ComfyUI port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Start ComfyUI with API enabled
CMD ["/app/start.sh"]
