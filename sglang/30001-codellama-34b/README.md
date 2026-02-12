# CodeLlama 34B Instruct - SGLang Server

SGLang server running CodeLlama 34B Instruct on GPUs 0+1 using tensor parallelism (TP=2).

## Overview

- **Model:** `codellama/CodeLlama-34b-Instruct-hf`
- **Port:** 30001
- **GPUs:** 0,1 (NVIDIA H200 NVL)
- **Tensor Parallelism:** TP=2
- **VRAM Required:** ~68GB total (~34GB per GPU)
- **VRAM Available:** ~87GB (GPU 0: ~43GB + GPU 1: ~44GB)

## Purpose

Provides an alternative to Ollama for multi-model GPU serving with better CUDA context handling. CodeLlama 34B is optimized for code generation, completion, and instruction following.

## Quick Start

```bash
# Start the server
./run.sh start

# Check status
./run.sh status

# View logs
./run.sh logs

# Stop the server
./run.sh stop
```

## API Usage

The server provides an OpenAI-compatible API at `http://localhost:30001/v1`.

### Chat Completions

```bash
curl http://localhost:30001/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "codellama/CodeLlama-34b-Instruct-hf",
    "messages": [
      {"role": "user", "content": "Write a Python function to calculate fibonacci numbers"}
    ]
  }'
```

### Health Check

```bash
curl http://localhost:30001/health
```

### List Models

```bash
curl http://localhost:30001/v1/models
```

## GPU Allocation

| GPU | Usage | Free VRAM |
|-----|-------|-----------|
| 0   | CodeLlama TP=2 | ~43GB |
| 1   | CodeLlama TP=2 | ~44GB |
| 2   | GLM-4.7 Q2 | ~5GB |
| 3   | Ollama (CPU) | Reserved |

## Model Details

CodeLlama 34B Instruct is a fine-tuned version of CodeLlama optimized for:

- Code generation and completion
- Instruction following
- Multi-language programming support
- Code debugging and explanation
- Technical documentation

**Model Card:** https://huggingface.co/codellama/CodeLlama-34b-Instruct-hf

## Commands

| Command | Description |
|---------|-------------|
| `start` | Start the SGLang server |
| `stop` | Stop the SGLang server |
| `restart` | Restart the SGLang server |
| `status` | Show server status and GPU usage |
| `logs` | Show server logs (tail -f) |
| `pull` | Download the CodeLlama 34B model |
| `pull-image` | Pull the SGLang Apptainer image |

## Technical Details

### Apptainer Configuration

- **Image:** `lmsysorg/sglang:latest` (shared SIF at `../shared/sglang.sif`)
- **Runtime:** `apptainer run --nv` (NVIDIA GPU support)
- ** mounts:**
  - `/data/models/huggingface:/root/.cache/huggingface` (model cache)
  - `/etc/ssl/certs:/etc/ssl/certs:ro` (SSL certificates for HTTPS)
  - `/etc/pki:/etc/pki:ro` (PKI for HTTPS)

### Environment Variables

- `HF_TOKEN` - HuggingFace authentication token (from `../../.env`)
- `CUDA_VISIBLE_DEVICES=0,1` - Restrict to GPUs 0 and 1
- `HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface` - Model cache location

### Server Arguments

- `--model-path codellama/CodeLlama-34b-Instruct-hf` - Model identifier
- `--host 0.0.0.0` - Listen on all interfaces
- `--port 30001` - API port
- `--tp 2` - Tensor parallelism across 2 GPUs

## Troubleshooting

### Server fails to start

Check logs for errors:
```bash
./run.sh logs
```

### GPU memory issues

Verify GPU usage:
```bash
nvidia-smi
```

### Port already in use

Check if port 30001 is available:
```bash
ss -tlnp | grep 30001
```

### Model download fails

The model will be downloaded automatically on first start (~64GB). Ensure:
- Sufficient disk space in `/data/models/huggingface`
- Network connectivity to HuggingFace
- Valid `HF_TOKEN` in `../../.env` (if required)

## Related Services

- **DeepSeek V2.5:** Port 30000 (GPUs 0-3, TP=4)
- **Ollama:** Port 11434 (GPU 3)
- **GLM-4.7 Q2:** GPU 2

## References

- [SGLang Documentation](https://sgl-project.github.io/)
- [CodeLlama Model Card](https://huggingface.co/codellama/CodeLlama-34b-Instruct-hf)
- [SYSTEM_CONSTRAINTS.md](../../SYSTEM_CONSTRAINTS.md)
