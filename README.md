# llama.cpp with CUDA on isarco01.disi.unitn.it

## Overview

This directory contains a llama.cpp server setup with CUDA support using Singularity containers. It runs the GLM-4-9B-Chat model on 4x NVIDIA H200 NVL GPUs.

## Hardware

- **GPUs:** 4x NVIDIA H200 NVL (149.3 GB total VRAM)
- **CUDA:** 13.1
- **Singularity:** Apptainer 1.4.5-2

## Files

| File | Description |
|------|-------------|
| llamacpp-cuda-complete.sif | Singularity image with llama.cpp + CUDA (4.7GB) |
| run-glm4-server.sh | Server control script |
| docker-compose.yml | Docker compose reference (not used on this system) |
| test-client.sh | Test client for the server |
| llamacpp.def | Singularity definition file |
| .gitignore | Git ignore patterns |

## Model

- **Name:** glm-4-9b-chat
- **Quantization:** Q5_K_M
- **File:** models/glm-4-9b-chat-Q5_K_M.gguf (6.7GB)
- **Layers:** 40
- **GPU offload:** All layers (ngl=99)

## Usage

### Server Control

```bash
# Check server status
./run-glm4-server.sh status

# Start server
./run-glm4-server.sh start

# Stop server
./run-glm4-server.sh stop

# Restart server
./run-glm4-server.sh restart
```

### Server Configuration

Default settings in run-glm4-server.sh:
- Port: 8080
- Host: 0.0.0.0 (all interfaces)
- GPU layers: 99 (all offloaded to GPU)
- Context size: 8192
- Threads: 8

### GPU Usage

When running, each GPU uses approximately 2.3-2.9GB of VRAM.

```bash
# Check GPU usage
nvidia-smi
```

## API Endpoints

### Health Check
```bash
curl http://localhost:8080/health
# Response: {"status":"ok"}
```

### Chat Completions
```bash
curl http://localhost:8080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "glm-4", "messages": [{"role": "user", "content": "Hello!"}]}'
```

### Models List
```bash
curl http://localhost:8080/v1/models
```

## Performance

- **Generation speed:** ~186 tokens/second
- **Memory per GPU:** ~2.5GB
- **GPU utilization:** ~95% during generation

## Access from Local Machine

To access this server from your local machine, use the SSH tunnel setup in ~/Develop/LLM/bears.disi.unitn.it/:

```bash
# On local machine
cd ~/Develop/LLM/bears.disi.unitn.it
./tunnel.sh start
```

Then access at http://localhost:8080.

## Git Repository

This setup is tracked at: https://github.com/marcorobol/isarco-llama

Large files are excluded via .gitignore:
- *.sif - Singularity images
- *.gguf - Model files
- llamacpp-sandbox/ - Build directories

## Building the Singularity Image

The image was built using the llamacpp.def definition file:

```bash
# Build (takes ~30 minutes)
singularity build --sandbox llamacpp-sandbox llamacpp.def

# Convert to SIF
singularity build llamacpp-cuda-complete.sif llamacpp-sandbox/
```

## Troubleshooting

### Server won't start
- Check if port 8080 is already in use: `lsof -i :8080`
- Check GPU availability: `nvidia-smi`
- Check logs: `tail -f llama-server.log`

### GPU memory issues
- Reduce NGP_LAYERS in run-glm4-server.sh
- Check for other GPU processes: `nvidia-smi`

### Stale PID file
If server is running but status shows it's not:
```bash
# Find actual PID
ps aux | grep llama-server

# Update PID file
echo <actual_pid> > ~/localai/llama-server.pid
```
