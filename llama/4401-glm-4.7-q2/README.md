# GLM-4.7 UD-Q2_K_XL - llama.cpp Server

355B parameter Mixture-of-Experts (MoE) model running via llama.cpp with UD-Q2_K_XL quantization.

## Overview

- **Model:** GLM-4.7 (355B MoE, ~52B active parameters)
- **Quantization:** UD-Q2_K_XL (~135GB total, 3 files)
- **Port:** 4401
- **GPUs:** 0,1,2,3 (4x NVIDIA H200 NVL)
- **Context:** Up to 131,072 tokens (configured: 65,536)

## Purpose

GLM-4.7 is Zhipu AI's flagship large language model with exceptional capabilities in Chinese and English. The UD-Q2_K_XL quantization provides a good balance between model quality and memory usage, making it suitable for general-purpose tasks.

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

The server provides an OpenAI-compatible API at `http://localhost:4401/v1`.

### Chat Completions

```bash
curl http://localhost:4401/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "glm-4.7-q2",
    "messages": [
      {"role": "user", "content": "写一个Python函数来计算斐波那契数列"}
    ]
  }'
```

### Health Check

```bash
curl http://localhost:4401/health
```

### List Models

```bash
curl http://localhost:4401/v1/models
```

## Model Details

GLM-4.7 is a Mixture-of-Experts (MoE) model with 355B total parameters (~52B active per token). Key features:

- **Multilingual:** Excellent Chinese and English capabilities
- **Long Context:** Supports up to 131,072 tokens
- **Large Knowledge Base:** Trained on diverse, high-quality data
- **Code Generation:** Strong programming capabilities

**Quantization Details:**
- UD-Q2_K_XL provides ~2-bit quantization with expert scaling
- ~135GB total model size (3 split files)
- Good balance between quality and memory efficiency

## GPU Memory Usage

| GPU | Usage | Approximate VRAM |
|-----|-------|------------------|
| 0   | GLM-4.7 TP=4 | ~34GB |
| 1   | GLM-4.7 TP=4 | ~34GB |
| 2   | GLM-4.7 TP=4 | ~34GB |
| 3   | GLM-4.7 TP=4 | ~34GB |

**Total:** ~135GB across 4 GPUs

## Commands

| Command | Description |
|---------|-------------|
| `start` | Start the llama-server |
| `stop` | Stop the llama-server |
| `restart` | Restart the llama-server |
| `status` | Show server status and GPU usage |
| `logs` | Show server logs (tail -f) |

## Technical Details

### Singularity Configuration

- **Image:** `../shared/llamacpp-cuda-complete.sif`
- **Runtime:** `singularity exec --nv` (NVIDIA GPU support)
- **Mounts:**
  - `/data/models:/models` (model cache)

### Server Arguments

- `-m /models/GLM-4.7-UD-Q2_K_XL-00001-of-00003.gguf` - Model path
- `-ngl 99` - Offload all layers to GPU
- `-c 65536` - Context window (65K tokens, max: 131072)
- `--port 4401` - API port
- `--host 0.0.0.0` - Listen on all interfaces
- `-t 32` - 32 CPU threads
- `--jinja` - Enable Jinja template support (required for GLM)
- `--fit on` - Optimize GPU VRAM utilization
- `--temp 1.0` - Temperature sampling
- `--top-p 0.95` - Top-p sampling
- `--repeat-penalty 1.0` - Disable repeat penalty (recommended for GLM)

### Environment Variables

- `CUDA_VISIBLE_DEVICES=0,1,2,3` - Use all 4 GPUs

## Model Files

The UD-Q2_K_XL quantization consists of 3 files stored in `/data/models/GLM-4.7-GGUF/UD-Q2_K_XL/`:

```
GLM-4.7-UD-Q2_K_XL-00001-of-00003.gguf (~45GB)
GLM-4.7-UD-Q2_K_XL-00002-of-00003.gguf (~45GB)
GLM-4.7-UD-Q2_K_XL-00003-of-00003.gguf (~45GB)
```

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

The model requires approximately 34GB VRAM per GPU. If you're experiencing memory issues:

1. Stop any conflicting services on GPUs 0-3
2. Reduce context size with `-c` parameter in `run.sh`
3. Consider using the Q4_K_XL quantization instead

### Port already in use

Check if port 4401 is available:
```bash
ss -tlnp | grep 4401
```

### Model not found

Ensure model files are in `/data/models/GLM-4.7-GGUF/UD-Q2_K_XL/`:

```bash
ls -lh /data/models/GLM-4.7-GGUF/UD-Q2_K_XL/
```

### Slow inference

GLM-4.7 is a large model. For faster inference:

1. Use GLM-4.7-Flash (port 4402) for faster responses
2. Reduce context size if not needed
3. Ensure all 4 GPUs are available

## Related Services

- **GLM-4.7-Flash Q4:** Port 4402 (faster, smaller model)
- **GLM-4.7-Flash Q4:** Port 4403 (alternative Flash instance)
- **DeepSeek V2.5 GGUF:** Port 5001 (4 GPUs)

## References

- [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)
- [GLM-4 Model Card](https://huggingface.co/thudm/glm-4-9b-chat)
- [SYSTEM_CONSTRAINTS.md](../../SYSTEM_CONSTRAINTS.md)
