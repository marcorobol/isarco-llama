# Codestral 22B v0.1 - SGLang Server

SGLang server running Codestral 22B v0.1 on GPU 1.

## Overview

- **Model:** `mistralai/Codestral-22B-v0.1`
- **Port:** 30002
- **GPU:** 1 (NVIDIA H200 NVL)
- **Tensor Parallelism:** TP=1
- **Context Length:** 8192 tokens
- **Memory Fraction:** 0.6

## Purpose

Provides an open-code alternative to CodeLlama for code generation tasks. Codestral 22B is Mistral AI's open-weight code model optimized for code generation, completion, and instruction following.

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

The server provides an OpenAI-compatible API at `http://localhost:30002/v1`.

### Chat Completions

```bash
curl http://localhost:30002/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "mistralai/Codestral-22B-v0.1",
    "messages": [
      {"role": "user", "content": "Write a Python function to calculate fibonacci numbers"}
    ]
  }'
```

### Health Check

```bash
curl http://localhost:30002/health
```

### List Models

```bash
curl http://localhost:30002/v1/models
```

### Generate Endpoint

```bash
curl http://localhost:30002/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "mistralai/Codestral-22B-v0.1",
    "prompt": "def hello_world():",
    "max_tokens": 128
  }'
```

## Model Details

Codestral 22B v0.1 is Mistral AI's open-weight code model trained on a diverse dataset of code and natural language related to code. Optimized for:

- Code generation and completion
- Instruction following
- Multi-language programming support
- Code debugging and explanation
- Technical documentation

**Model Card:** https://huggingface.co/mistralai/Codestral-22B-v0.1

**License:** Apache 2.0

## Commands

| Command | Description |
|---------|-------------|
| `start` | Start the SGLang server |
| `stop` | Stop the SGLang server |
| `restart` | Restart the SGLang server |
| `status` | Show server status and GPU usage |
| `logs` | Show server logs (tail -f) |
| `pull` | Download the Codestral 22B model |
| `pull-image` | Pull the SGLang Apptainer image |

## Technical Details

### Apptainer Configuration

- **Image:** `lmsysorg/sglang:latest` (shared SIF at `../shared/sglang.sif`)
- **Runtime:** `apptainer run --nv` (NVIDIA GPU support)
- **Mounts:**
  - `/data/models/huggingface:/root/.cache/huggingface` (model cache)
  - `/etc/ssl/certs:/etc/ssl/certs:ro` (SSL certificates for HTTPS)
  - `/etc/pki:/etc/pki:ro` (PKI for HTTPS)

### Environment Variables

- `HF_TOKEN` - HuggingFace authentication token (from `../../.env`)
- `CUDA_VISIBLE_DEVICES=1` - Restrict to GPU 1
- `HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface` - Model cache location
- `PYTHONUNBUFFERED=1` - Disable Python output buffering

### Server Arguments

- `--model-path mistralai/Codestral-22B-v0.1` - Model identifier
- `--host 0.0.0.0` - Listen on all interfaces
- `--port 30002` - API port
- `--tp 1` - Tensor parallelism (single GPU)
- `--context-length 8192` - Maximum context window size
- `--mem-fraction-static 0.6` - Static memory allocation (60% of GPU VRAM)

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

Codestral 22B requires approximately 40-45GB VRAM. With `--mem-fraction-static 0.6`, it will use about 26GB of the available ~44GB on GPU 1.

### Port already in use

Check if port 30002 is available:
```bash
ss -tlnp | grep 30002
```

### Model download fails

The model will be downloaded automatically on first start (~40GB). Ensure:
- Sufficient disk space in `/data/models/huggingface`
- Network connectivity to HuggingFace
- Valid `HF_TOKEN` in `../../.env` (Codestral is open access but token may be required)

### Context length issues

The default context length is 8192 tokens. For longer contexts, modify the `--context-length` argument in `run.sh` and restart.

## Related Services

- **DeepSeek V2.5:** Port 30000 (GPUs 0-3, TP=4)
- **CodeLlama 34B:** Port 30001 (GPUs 0+1, TP=2)
- **Ollama:** Port 11434 (GPU 3)

## References

- [SGLang Documentation](https://sgl-project.github.io/)
- [Codestral Model Card](https://huggingface.co/mistralai/Codestral-22B-v0.1)
- [Codestral Documentation](https://docs.mistral.ai/codestral)
- [SYSTEM_CONSTRAINTS.md](../../SYSTEM_CONSTRAINTS.md)
