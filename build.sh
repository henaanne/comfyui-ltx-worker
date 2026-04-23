#!/bin/bash

# Build script for ComfyUI + LTX 2.3 Docker image
# This script builds the Docker image for RunPod deployment

set -e

# Configuration
IMAGE_NAME="comfyui-ltx-2.3"
IMAGE_TAG="latest"
DOCKERFILE_PATH="."
BUILD_CONTEXT="."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}Building ComfyUI + LTX 2.3 Docker Image${NC}"
echo -e "${GREEN}==========================================${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo -e "${YELLOW}Warning: Dockerfile not found in current directory${NC}"
    echo -e "${YELLOW}Make sure you're in the infrastructure/docker/comfyui-ltx directory${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build arguments (optional)
BUILD_ARGS=""
# Uncomment to add build arguments
# BUILD_ARGS="--build-arg PYTHON_VERSION=3.11"

# Build the Docker image
echo -e "${GREEN}Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
echo -e "Dockerfile: ${DOCKERFILE_PATH}/Dockerfile"
echo -e "Context: ${BUILD_CONTEXT}"

docker build \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -f "${DOCKERFILE_PATH}/Dockerfile" \
    ${BUILD_ARGS} \
    "${BUILD_CONTEXT}"

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
    echo -e "${GREEN}Image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
    
    # Show image information
    echo -e "\n${YELLOW}Image details:${NC}"
    docker images | grep "${IMAGE_NAME}"
    
    # Optional: Run a test container
    echo -e "\n${YELLOW}To test the image:${NC}"
    echo -e "docker run --gpus all -p 8188:8188 --rm ${IMAGE_NAME}:${IMAGE_TAG}"
    
    # Optional: Push to registry
    echo -e "\n${YELLOW}To push to Docker Hub (if configured):${NC}"
    echo -e "1. docker tag ${IMAGE_NAME}:${IMAGE_TAG} yourusername/${IMAGE_NAME}:${IMAGE_TAG}"
    echo -e "2. docker push yourusername/${IMAGE_NAME}:${IMAGE_TAG}"
    
    # RunPod specific instructions
    echo -e "\n${YELLOW}For RunPod deployment:${NC}"
    echo -e "1. Push to Docker Hub or RunPod's container registry"
    echo -e "2. In RunPod dashboard, create a new template"
    echo -e "3. Use the Docker image URL: yourusername/${IMAGE_NAME}:${IMAGE_TAG}"
    echo -e "4. Set container port: 8188"
    echo -e "5. Set volume mounts for models if needed"
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
fi