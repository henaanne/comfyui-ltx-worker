@echo off
REM Build script for ComfyUI + LTX 2.3 Docker image (Windows)
REM This script builds the Docker image for RunPod deployment

set IMAGE_NAME=comfyui-ltx-2.3
set IMAGE_TAG=latest
set DOCKERFILE_PATH=.
set BUILD_CONTEXT=.

echo ==========================================
echo Building ComfyUI + LTX 2.3 Docker Image
echo ==========================================

REM Check if Docker is installed
where docker >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Docker is not installed or not in PATH
    exit /b 1
)

REM Check if we're in the right directory
if not exist "Dockerfile" (
    echo Warning: Dockerfile not found in current directory
    echo Make sure you're in the infrastructure/docker/comfyui-ltx directory
    set /p CONTINUE=Continue anyway? (y/n): 
    if /i not "%CONTINUE%"=="y" (
        exit /b 1
    )
)

REM Build the Docker image
echo Building Docker image: %IMAGE_NAME%:%IMAGE_TAG%
echo Dockerfile: %DOCKERFILE_PATH%\Dockerfile
echo Context: %BUILD_CONTEXT%

docker build ^
    -t "%IMAGE_NAME%:%IMAGE_TAG%" ^
    -f "%DOCKERFILE_PATH%\Dockerfile" ^
    "%BUILD_CONTEXT%"

REM Check if build was successful
if %ERRORLEVEL% equ 0 (
    echo ✅ Docker image built successfully!
    echo Image: %IMAGE_NAME%:%IMAGE_TAG%
    
    echo.
    echo Image details:
    docker images | findstr "%IMAGE_NAME%"
    
    echo.
    echo To test the image:
    echo docker run --gpus all -p 8188:8188 --rm %IMAGE_NAME%:%IMAGE_TAG%
    
    echo.
    echo For RunPod deployment:
    echo 1. Push to Docker Hub or RunPod's container registry
    echo 2. In RunPod dashboard, create a new template
    echo 3. Use the Docker image URL: yourusername/%IMAGE_NAME%:%IMAGE_TAG%
    echo 4. Set container port: 8188
    echo 5. Set volume mounts for models if needed
) else (
    echo ❌ Docker build failed!
    exit /b 1
)