# LLM Server Suite on isarco01.disi.unitn.it

## Overview

This directory contains multiple LLM server backends including llama.cpp, SGLang, Ollama, and LocalAI. It runs various large language models including DeepSeek V2.5, GLM-4.7 variants, Codestral, CodeLlama, and more on 4x NVIDIA H200 NVL GPUs.

**See also:** [SYSTEM_CONSTRAINTS.md](SYSTEM_CONSTRAINTS.md) for system limits and constraints.

## Hardware

- **GPUs:** 4x NVIDIA H200 NVL (575 GB total VRAM)
- **CUDA:** 13.1
- **Singularity:** Apptainer 1.4.5-2

## Directory Structure

```
isarco-llama/
├── llama/                                # llama.cpp servers
│   ├── shared/
│   │   └── llamacpp-cuda-complete.sif   # Shared Singularity image (~4.7GB)
│   ├── 4401-glm-4.7-q2/                 # GLM-4.7 Q2 quantization (port 4401)
│   ├── 4402-glm-4.7-flash-q4/           # GLM-4.7-Flash Q4 quantization (port 4402)
│   ├── 4403-glm-4.7-q8/                 # GLM-4.7-Flash Q4 quantization (port 4403)
│   └── 5001-deepseek-v2.5-gguf/         # DeepSeek V2.5 GGUF Q6_K (port 5001)
├── sglang/                               # SGLang servers
│   ├── shared/
│   │   └── sglang.sif                    # Shared SGLang Singularity image
│   ├── 30000-deepseek-v2.5/             # DeepSeek V2.5 FP16 (port 30000)
│   ├── 30001-codellama-34b/             # CodeLlama 34B Instruct (port 30001)
│   └── 30002-codestral-22b/             # Codestral 22B v0.1 (port 30002)
├── ollama/                               # Ollama model management (port 11434)
├── localai/                              # LocalAI OpenAI-compatible API (port 8081)
├── SYSTEM_CONSTRAINTS.md                 # System limits and constraints
└── README.md                             # This file
```

## Available Services

| Service | Directory | Port | Model | Quantization/Backend | GPUs |
|---------|-----------|------|-------|---------------------|------|
| **SGLang Servers** |
| DeepSeek V2.5 | `sglang/30000-deepseek-v2.5/` | 30000 | DeepSeek V2.5 | FP16/FP8, TP=4 | 0-3 |
| CodeLlama 34B | `sglang/30001-codellama-34b/` | 30001 | CodeLlama-34b-Instruct | FP16, TP=2 | 0,1 |
| Codestral 22B | `sglang/30002-codestral-22b/` | 30002 | Codestral-22B-v0.1 | FP16, TP=1 | 1 |
| **llama.cpp Servers** |
| DeepSeek V2.5 | `llama/5001-deepseek-v2.5-gguf/` | 5001 | DeepSeek V2.5 | Q6_K (~193GB) | 0,1 |
| GLM-4.7 Q2 | `llama/4401-glm-4.7-q2/` | 4401 | GLM-4.7 | Q2_K_XL (~135GB) | 0-3 |
| GLM-4.7-Flash Q4 | `llama/4402-glm-4.7-flash-q4/` | 4402 | GLM-4.7-Flash | Q4_K_XL (~18GB) | 0-3 |
| GLM-4.7-Flash Q4 #2 | `llama/4403-glm-4.7-q8/` | 4403 | GLM-4.7-Flash | Q4_K_XL (~18GB) | 0-3 |
| **Other Servers** |
| Ollama | `ollama/` | 11434 | Multiple | Various | 3 |
| LocalAI | `localai/` | 8081 | GLM-4.7 variants | llama-cpp | 2,3 |

## Models

### DeepSeek V2.5 GGUF (236B parameter MoE model)
- **Parameters:** 235.7B total
- **Architecture:** DeepSeek2 with MLA (Multi-Head Latent Attention)
- **Context window:** Up to 163,840 tokens
- **Quantization:** Q6_K (~193GB total)
- **Expert configuration:** 160 experts, 6 active per token
- **GPU allocation:** Split across GPUs 0-1 with `--fit on`
- **Performance:** ~40 tokens/second generation
- **Required flags:**
  - `--fit on` - Auto-distribute across available GPUs
  - `-ngl 99` - Full GPU offload
  - `--repeat-penalty 1.0` - Disable repeat penalty

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

Services can run simultaneously if they don't exceed GPU memory limits:

**Current GPU Allocation:**
```
GPU 0: DeepSeek V2.5 GGUF (~116GB)
GPU 1: DeepSeek V2.5 GGUF (~112GB)
GPU 2: Available (or GLM-4.7 Q2 when running)
GPU 3: Ollama (when running)
```

#### CUDA MPS (Multi-Process Service)

CUDA MPS allows multiple models to share the same GPU more efficiently by multiplexing GPU contexts. This is particularly useful when running smaller models concurrently.

**To enable CUDA MPS**:
```bash
# Start CUDA MPS to allow multiple models per GPU
# https://amirsojodoodi.github.io/posts/Enabling-MPS/
echo "Starting CUDA MPS daemon"
nvidia-cuda-mps-control -d
```

**Benefits:**
- Better GPU utilization when running multiple smaller models
- Reduced memory overhead for multiple processes
- Improved throughput for concurrent inference

**Notes:**
- See [https://amirsojodi.github.io/posts/Enabling-MPS/](https://amirsojodi.github.io/posts/Enabling-MPS/) for details

**Example: Running DeepSeek + Ollama**
```bash
# Terminal 1 - DeepSeek V2.5 GGUF (port 5001, GPUs 0-1)
cd llama/5001-deepseek-v2.5-gguf && ./run.sh start

# Terminal 2 - Ollama (port 11434, GPU 3)
cd ollama && ./run.sh start
```

**Note:** Cannot run GLM-4.7 Q2 and DeepSeek V2.5 GGUF simultaneously (both need GPU 0-1 or GPU 2).

**Checking GPU availability:**
```bash
nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv
```

### Server Configuration

Default settings in each service's run.sh:
- **Port:** Service-specific (4401, 4402, or 4403)
- **Host:** 0.0.0.0 (all interfaces)
- **GPU layers:** 99 (all offloaded to GPU)
- **Context size:** 65536 (configurable up to 131072 for GLM-4.7, 202752 for Flash)
- **Threads:** 32

### GPU Usage

**Current Allocation (DeepSeek V2.5 GGUF running):**
```
GPU 0: 116GB / 143GB (DeepSeek V2.5 GGUF)
GPU 1: 112GB / 143GB (DeepSeek V2.5 GGUF)
GPU 2: ~0GB / 143GB (Available)
GPU 3: ~0GB / 143GB (Available for Ollama)
```

**Alternative Allocation (GLM-4.7 Q2 running):**
```
GPU 0-3: ~135GB total distributed (GLM-4.7 Q2)
```

```bash
# Check GPU usage
nvidia-smi

# Detailed GPU info
nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv
```

## API Endpoints

Each service exposes standard OpenAI-compatible endpoints on its respective port.

### DeepSeek V2.5 GGUF (Port 5001) - Primary Model
```bash
# Health check
curl http://localhost:5001/health

# Chat completions
curl http://localhost:5001/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
      "model": "deepseek-v2.5",
      "messages": [{"role": "user", "content": "Write a Python function to check if a number is prime"}],
      "max_tokens": 500
    }'

# Models list
curl http://localhost:5001/v1/models

# Web UI (built-in)
# Open http://localhost:5001 in browser
```

**Performance:** ~40 tokens/second generation

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

### Ollama (Port 11434)
```bash
# List installed models
curl http://localhost:11434/api/tags

# Generate completion
curl http://localhost:11434/api/generate \
    -d '{"model": "llama2", "prompt": "Why is the sky blue?"}'

# Chat completion
curl http://localhost:11434/api/chat \
    -d '{
      "model": "llama2",
      "messages": [{"role": "user", "content": "Hello!"}]
    }'

# Pull a model
cd ollama && ./run.sh pull llama2

# Run interactive model
cd ollama && ./run.sh run llama2
```

**Note:** Ollama runs on GPU 3 to avoid conflicts with DeepSeek V2.5 GGUF.

### SGLang Services

#### DeepSeek V2.5 (Port 30000)
```bash
# Health check
curl http://localhost:30000/health

# Chat completions
curl http://localhost:30000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V2.5",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

#### CodeLlama 34B (Port 30001)
```bash
# Health check
curl http://localhost:30001/health

# Chat completions
curl http://localhost:30001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "codellama/CodeLlama-34b-Instruct-hf",
    "messages": [{"role": "user", "content": "Write a Python hello world"}]
  }'
```

#### Codestral 22B (Port 30002)
```bash
# Health check
curl http://localhost:30002/health

# Chat completions
curl http://localhost:30002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistralai/Codestral-22B-v0.1",
    "messages": [{"role": "user", "content": "Write a Python hello world"}]
  }'
```

### LocalAI (Port 8081)
```bash
# List models
curl http://localhost:8081/v1/models

# Chat completions (OpenAI-compatible)
curl http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "GLM-4.7-Q8_0",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Performance

### DeepSeek V2.5 GGUF Q6_K
- **Prompt processing:** ~40 tokens/second
- **Generation:** ~40 tokens/second
- **Memory usage:** ~116GB + 112GB across GPUs 0-1
- **GPU utilization:** 78-81% VRAM
- **Context window:** 8192 tokens (configurable up to 163840)

### GLM-4.7
- **Generation speed:** ~186 tokens/second
- **Memory per GPU:** ~2.5GB for context
- **GPU utilization:** ~95% during generation

## Access from Local Machine

To access these servers from your local machine, use the SSH tunnel setup in ~/Develop/LLM/bears.disi.unitn.it/:

```bash
# On local machine
cd ~/Develop/LLM/bears.disi.unitn.it
./tunnel.sh start
```

Then access at:
- http://localhost:5001 (DeepSeek V2.5 GGUF) - **Primary llama.cpp model**
- http://localhost:4401 (GLM-4.7 Q2)
- http://localhost:4402 (GLM-4.7-Flash Q4)
- http://localhost:4403 (GLM-4.7-Flash Q4 #2)
- http://localhost:11434 (Ollama)
- http://localhost:30000 (DeepSeek V2.5 SGLang) - **Primary SGLang model**
- http://localhost:30001 (CodeLlama 34B SGLang)
- http://localhost:30002 (Codestral 22B SGLang)
- http://localhost:8081 (LocalAI)

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
- Check if port is already in use: `lsof -i :5001` (or 30000-30002, 4401-4403, 8081, 11434)
- Check GPU availability: `nvidia-smi`
- Check logs: `cd <service-dir> && ./run.sh logs`
- Ensure enough GPU memory for your chosen service

### Port conflicts
If you need to change a port, edit files in service directory:
- **SGLang:** Edit `run.sh` and update `PORT=` variable
- **llama.cpp:** Edit `run.sh` and update `PORT=` variable
- **Ollama:** Edit `run.sh` and update `PORT=` variable
- **LocalAI:** Edit `run.sh` and update `PORT=` variable

### GPU memory issues
- **DeepSeek V2.5 GGUF:** Needs ~228GB across GPUs 0-1 with `--fit on`
- **DeepSeek V2.5 SGLang:** Needs ~544GB across GPUs 0-3
- **CodeLlama 34B SGLang:** Needs ~68GB across GPUs 0-1
- **Codestral 22B SGLang:** Needs ~26GB on GPU 1
- **GLM-4.7 Q2:** Needs ~135GB distributed across all 4 GPUs
- Reduce GPU layers in the service's run.sh (default: 99)
- Check for other GPU processes: `nvidia-smi`
- Try running services one at a time
- Use smaller quantization if needed (Q4 instead of Q6/Q8)

### DeepSeek V2.5 GGUF won't load
**Symptom:** "cudaMalloc failed: out of memory"

**Solutions:**
1. Ensure `--fit on` flag is set (not `-ts` or tensor split)
2. Check `CUDA_VISIBLE_DEVICES=0,1` is set correctly
3. Verify GPUs 0-1 are free: `nvidia-smi`
4. Stop conflicting services (GLM-4.7 uses all 4 GPUs)

### Model download failed
**For DeepSeek V2.5 GGUF:**
```bash
cd llama/5001-deepseek-v2.5-gguf
./download.sh  # Resumes automatically
```

### Stale PID file
If server is running but status shows it's not:
```bash
# Find actual PID
ps aux | grep llama-server

# Update PID file
echo <actual_pid> > ~/isarco-llama/llama/5001-deepseek-v2.5-gguf/llama-server.pid
```

## System Constraints

**Important limitations to be aware of:**
- **No sudo access** - Use Singularity instead of Docker
- **No Docker** - Singularity/Apptainer only
- **SSL certificates** - Must mount for HTTPS in Singularity:
  ```bash
  -B /etc/ssl/certs:/etc/ssl/certs:ro \
  -B /etc/pki:/etc/pki:ro
  ```
- **GPU memory:** ~143GB per GPU, plan model allocation carefully
- **Storage:** 3.5TB total on /data partition

**See [SYSTEM_CONSTRAINTS.md](SYSTEM_CONSTRAINTS.md) for complete documentation.**

## Quick Start

**Start DeepSeek V2.5 GGUF (llama.cpp, recommended for most use cases):**
```bash
cd /home/marco.robol/isarco-llama/llama/5001-deepseek-v2.5-gguf
./run.sh start

# Test
curl http://localhost:5001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "deepseek-v2.5", "messages": [{"role": "user", "content": "Hello!"}]}'
```

**Start DeepSeek V2.5 SGLang (higher quality, more memory):**
```bash
cd /home/marco.robol/isarco-llama/sglang/30000-deepseek-v2.5
./run.sh start

# Test
curl http://localhost:30000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "deepseek-ai/DeepSeek-V2.5", "messages": [{"role": "user", "content": "Hello!"}]}'
```

**Check all running services:**
```bash
ps aux | grep -E 'llama-server|ollama|sglang|localai'
nvidia-smi
```
