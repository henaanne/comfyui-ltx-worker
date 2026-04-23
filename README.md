# ComfyUI + LTX 2.3 Docker Image for RunPod

This Docker image packages ComfyUI with LTX 2.3 integration for video and image generation on cloud GPUs via RunPod.

## Overview

The image includes:
- **ComfyUI** (latest) with API enabled
- **LTX 2.3** integration via ComfyUI-LTXVideo custom nodes
- **LTX 2.3 Python packages** (ltx-core, ltx-pipelines, ltx-trainer)
- **CUDA 12.1** with cuDNN 8 support
- **Python 3.11** with uv package manager
- **Optimized for RTX 4090** (24GB VRAM) on RunPod

## Prerequisites

1. **RunPod Account**: Create an account at [runpod.io](https://runpod.io)
2. **Docker**: Installed locally for building the image
3. **Docker Hub Account** (optional): For pushing the image to a registry
4. **LTX 2.3 Models**: Download from HuggingFace (see below)

## Building the Docker Image

### On Linux/macOS:
```bash
cd infrastructure/docker/comfyui-ltx
chmod +x build.sh start.sh
./build.sh
```

### On Windows:
```bash
cd infrastructure\docker\comfyui-ltx
build.bat
```

## Model Download

LTX 2.3 requires model checkpoints. Download these from HuggingFace:

1. **Main model**: `ltx-2.3-22b-distilled-1.1.safetensors`
2. **Spatial upscaler**: `ltx-2.3-spatial-upscaler-x2-1.1.safetensors`
3. **Distilled LoRA** (optional): `ltx-2.3-22b-distilled-lora-384-1.1.safetensors`

**Download URLs**:
- https://huggingface.co/Lightricks/LTX-2.3
- https://huggingface.co/Lightricks/LTX-Video-2.3

**Place models in**:
- `/app/comfyui/models/checkpoints/` inside the container
- Or mount as volume: `-v /path/to/models:/app/comfyui/models/checkpoints`

## Deployment to RunPod

### Option 1: Serverless Endpoint (Production/Automated)

Serverless endpoints auto-scale to zero when idle ($0 cost), perfect for automated generation via `mcp-creative-engine`.

#### Steps:
1. **Push image to registry** (Docker Hub or RunPod's registry):
   ```bash
   docker tag comfyui-ltx-2.3:latest yourusername/comfyui-ltx-2.3:latest
   docker push yourusername/comfyui-ltx-2.3:latest
   ```

2. **Create Serverless Template** in RunPod:
   - Go to **Serverless** → **My Templates** → **+ New Template**
   - **Container Image**: `yourusername/comfyui-ltx-2.3:latest`
   - **Container Port**: `8188`
   - **Volume Mounts** (optional):
     - For models: `/path/to/models:/app/comfyui/models/checkpoints`
   - **Environment Variables**:
     - `PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512`
     - `CUDA_LAUNCH_BLOCKING=0`
   - **GPU Types**: Select `RTX 4090` (24GB)
   - **Idle Timeout**: 300 seconds (5 minutes)
   - **Max Workers**: 1-2 (depending on budget)

3. **Deploy Endpoint**:
   - Go to **Serverless** → **My Endpoints** → **+ New Endpoint**
   - Select your template
   - Configure scaling (recommended: min 0, max 1)
   - Click **Deploy**

4. **Test the endpoint**:
   ```bash
   # Get endpoint URL from RunPod dashboard
   ENDPOINT_URL="https://api.runpod.ai/v2/your-endpoint-id"
   RUNPOD_API_KEY="your-runpod-api-key"
   
   curl -X POST \
     -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
     -H "Content-Type: application/json" \
     -d '{"input": {"prompt": "test"}}' \
     "${ENDPOINT_URL}/run"
   ```

### Option 2: GPU Pod (Creative Sandbox)

GPU Pods provide full ComfyUI web UI for creative work and experimentation.

#### Steps:
1. **Push image to registry** (same as above)

2. **Create GPU Pod**:
   - Go to **GPU Pods** → **+ Deploy**
   - **Template**: Select **Custom Container**
   - **Container Image**: `yourusername/comfyui-ltx-2.3:latest`
   - **Container Port**: `8188`
   - **Volume Mounts**:
     - For models: `/path/to/models:/app/comfyui/models/checkpoints`
     - For outputs: `/path/to/outputs:/app/comfyui/output`
   - **GPU Type**: `RTX 4090` (24GB)
   - **Deploy Type**: **On-Demand** ($0.44/hr) or **Spot** ($0.34/hr)

3. **Access ComfyUI**:
   - After deployment, click **Connect** → **HTTP Service**
   - Open the provided URL in browser
   - ComfyUI web UI will be available at `http://<pod-ip>:8188`

4. **Stop when done** to avoid charges:
   - Go to **GPU Pods** → Select pod → **Stop**

## Integration with HeNåAnne Platform

### Update Environment Variables

In your `.env` file, update the ComfyUI URL to point to RunPod:

```env
# For Serverless endpoint
COMFYUI_BASE_URL=https://api.runpod.ai/v2/your-endpoint-id

# For GPU Pod (direct)
# COMFYUI_BASE_URL=http://<pod-ip>:8188

# RunPod API Key (for serverless)
RUNPOD_API_KEY=your-runpod-api-key
RUNPOD_SERVERLESS_ENDPOINT=your-endpoint-id
```

### Update mcp-creative-engine

The `mcp-creative-engine` server automatically uses the `COMFYUI_BASE_URL` environment variable. No code changes needed.

### Test Integration

1. Start `mcp-creative-engine`:
   ```bash
   cd mcp-servers/mcp-creative-engine
   npm run dev
   ```

2. Test video generation:
   ```bash
   # Use the MCP client or test via curl
   curl -X POST http://localhost:3005/sse \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc": "2.0",
       "method": "tools/call",
       "params": {
         "name": "generate_video",
         "arguments": {
           "prompt": "A colorful psychedelic art pattern",
           "duration_seconds": 5
         }
       }
     }'
   ```

## Cost Optimization

### Serverless Endpoint
- **Cost**: ~$0.44/hr when active, $0 when idle
- **Optimization**: Set idle timeout to 300 seconds (5 minutes)
- **Auto-scaling**: Min workers = 0, Max workers = 1

### GPU Pod
- **On-Demand**: $0.44/hr - always available
- **Spot**: $0.34/hr - may be interrupted, good for experimentation
- **Always stop pods** when not in use

### Model Storage
- Store models in persistent volume to avoid re-downloading
- Consider RunPod's network storage for faster pod startup

## Troubleshooting

### Common Issues

1. **"Out of memory" errors**:
   - Ensure using RTX 4090 (24GB) not lower VRAM GPU
   - Reduce video resolution in ComfyUI workflow
   - Use `--normalvram` instead of `--highvram` in start.sh

2. **LTX models not found**:
   - Verify models are in `/app/comfyui/models/checkpoints/`
   - Check file permissions
   - Download using: `wget -P /app/comfyui/models/checkpoints/ <model-url>`

3. **ComfyUI not starting**:
   - Check logs: `docker logs <container-id>`
   - Verify port 8188 is not in use
   - Check CUDA availability: `nvidia-smi`

4. **Slow generation**:
   - Ensure GPU is being used (check `nvidia-smi` during generation)
   - Use distilled model for faster inference
   - Reduce video length/resolution

### Logs and Monitoring

- **Container logs**: `docker logs <container-id>`
- **RunPod logs**: Available in pod/endpoint dashboard
- **GPU utilization**: Monitor via `nvidia-smi` or RunPod metrics

## Maintenance

### Updating the Image
1. Update dependencies in Dockerfile
2. Rebuild: `./build.sh`
3. Push to registry: `docker push yourusername/comfyui-ltx-2.3:latest`
4. Redeploy on RunPod

### Model Updates
1. Download new models to volume mount
2. Restart pods/endpoints
3. Test with sample generation

## Support

For issues with:
- **Docker image**: Check Docker build logs
- **RunPod deployment**: RunPod documentation and support
- **LTX 2.3 models**: Lightricks/HuggingFace documentation
- **Integration**: HeNåAnne platform documentation

## References

- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [LTX 2.3 GitHub](https://github.com/Lightricks/LTX-2)
- [ComfyUI-LTXVideo](https://github.com/Lightricks/ComfyUI-LTXVideo)
- [RunPod Documentation](https://docs.runpod.io)
- [HeNåAnne Blueprint](BLUEPRINT.md)