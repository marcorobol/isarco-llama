# llama.cpp with CUDA on isarco01.disi.unitn.it

## Overview

This directory contains llama.cpp server setups with CUDA support using Singularity containers. It runs multiple GLM-4.7 model variants on 4x NVIDIA H200 NVL GPUs.

## Hardware

- **GPUs:** 4x NVIDIA H200 NVL (575 GB total VRAM)
- **CUDA:** 13.1
- **Singularity:** Apptainer 1.4.5-2

## Directory Structure

```
llama/
├── shared/
│   └── llamacpp-cuda-complete.sif    # Shared Singularity image (4.7GB)
├── 4401-glm-4.7-q2/                  # GLM-4.7 Q2 quantization (port 4401)
│   ├── docker-compose.yml
│   ├── run.sh
│   └── llamacpp.def
├── 4402-glm-4.7-flash-q4/            # GLM-4.7-Flash Q4 quantization (port 4402)
│   ├── docker-compose.yml
│   ├── run.sh
│   └── test-client.sh
└── 4403-glm-4.7-q8/                  # GLM-4.7 Q8 quantization (port 4403)
    ├── docker-compose.yml
    ├── run.sh
    └── test-client.sh
```

## Available Services

| Service | Directory | Port | Model | Quantization |
|---------|-----------|------|-------|--------------|
| GLM-4.7 Q2 | `llama/4401-glm-4.7-q2/` | 4401 | GLM-4.7 | Q2_K_XL (~135GB) |
| GLM-4.7-Flash Q4 | `llama/4402-glm-4.7-flash-q4/` | 4402 | GLM-4.7-Flash | Q4_K_XL (~18GB) |
| GLM-4.7 Q8 | `llama/4403-glm-4.7-q8/` | 4403 | GLM-4.7 | Q8_0 (~250GB) |

## Models

### GLM-4.7 (355B parameter MoE model)
- **Context window:** Up to 131,072 tokens
- **Quantizations available:** Q2_K_XL (~135GB), Q8_0 (~250GB)
- **Required flags:**
  - `--jinja` - Required for correct chat template handling
  - `--fit on` - Optimize GPU utilization across all available VRAM
  - `--repeat-penalty 1.0` - Disable repeat penalty (recommended for GLM models)

### GLM-4.7-Flash (30B MoE, ~3.6B active parameters)
- **Context window:** Up to 202,752 tokens
- **Quantization:** Q4_K_XL (~18GB)
- **Additional flags:**
  - `--min-p 0.01` - Additional parameter for GLM-4.7-Flash

All models use full GPU offload (ngl=99) for maximum performance.

## Usage

### Server Control

Each service has its own control script. Example for GLM-4.7 Q2 (port 4401):

```bash
# Navigate to service directory
cd llama/4401-glm-4.7-q2

# Check server status
./run.sh status

# Start server
./run.sh start

# Stop server
./run.sh stop

# Restart server
./run.sh restart

# View logs
./run.sh logs
```

### Running Multiple Services

All three services can run simultaneously since they use different ports:

```bash
# Terminal 1 - GLM-4.7 Q2 (port 4401)
cd llama/4401-glm-4.7-q2 && ./run.sh start

# Terminal 2 - GLM-4.7-Flash Q4 (port 4402)
cd llama/4402-glm-4.7-flash-q4 && ./run.sh start

# Terminal 3 - GLM-4.7 Q8 (port 4403)
cd llama/4403-glm-4.7-q8 && ./run.sh start
```

### Server Configuration

Default settings in each service's run.sh:
- **Port:** Service-specific (4401, 4402, or 4403)
- **Host:** 0.0.0.0 (all interfaces)
- **GPU layers:** 99 (all offloaded to GPU)
- **Context size:** 65536 (configurable up to 131072 for GLM-4.7, 202752 for Flash)
- **Threads:** 32

### GPU Usage

Each GPU uses approximately 140-150GB of VRAM when running the larger GLM-4.7 models.

```bash
# Check GPU usage
nvidia-smi
```

## API Endpoints

Each service exposes standard OpenAI-compatible endpoints on its respective port.

### GLM-4.7 Q2 (Port 4401)
```bash
# Health check
curl http://localhost:4401/health

# Chat completions
curl http://localhost:4401/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "glm-4", "messages": [{"role": "user", "content": "Hello!"}]}'

# Models list
curl http://localhost:4401/v1/models
```

### GLM-4.7-Flash Q4 (Port 4402)
```bash
# Health check
curl http://localhost:4402/health

# Chat completions
curl http://localhost:4402/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "glm-4-flash", "messages": [{"role": "user", "content": "Hello!"}]}'
```

### GLM-4.7 Q8 (Port 4403)
```bash
# Health check
curl http://localhost:4403/health

# Chat completions
curl http://localhost:4403/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "glm-4", "messages": [{"role": "user", "content": "Hello!"}]}'
```

## Performance

- **Generation speed:** ~186 tokens/second
- **Memory per GPU:** ~2.5GB
- **GPU utilization:** ~95% during generation

## Access from Local Machine

To access these servers from your local machine, use the SSH tunnel setup in ~/Develop/LLM/bears.disi.unitn.it/:

```bash
# On local machine
cd ~/Develop/LLM/bears.disi.unitn.it
./tunnel.sh start
```

Then access at:
- http://localhost:4401 (GLM-4.7 Q2)
- http://localhost:4402 (GLM-4.7-Flash Q4)
- http://localhost:4403 (GLM-4.7 Q8)

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
- Check if port is already in use: `lsof -i :4401` (or 4402, 4403)
- Check GPU availability: `nvidia-smi`
- Check logs: `cd llama/4401-glm-4.7-q2 && tail -f llama-server.log`

### Port conflicts
If you need to change a port, edit both files in the service directory:
- `run.sh`: Update `PORT=` variable
- `docker-compose.yml`: Update ports mapping and `--port` flag

### GPU memory issues
- Reduce NGP_LAYERS in the service's run.sh
- Check for other GPU processes: `nvidia-smi`
- Try running services one at a time

### Stale PID file
If server is running but status shows it's not:
```bash
# Find actual PID
ps aux | grep llama-server

# Update PID file
echo <actual_pid> > ~/isarco-llama/llama/4401-glm-4.7-q2/llama-server.pid
```
