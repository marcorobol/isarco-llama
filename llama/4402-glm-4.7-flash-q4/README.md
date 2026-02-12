# GLM-4.7-Flash UD-Q4_K_XL - llama.cpp Server

30B parameter Mixture-of-Experts (MoE) Flash model running via llama.cpp with UD-Q4_K_XL quantization.

## Overview

- **Model:** GLM-4.7-Flash (30B MoE, ~3.6B active parameters)
- **Quantization:** UD-Q4_K_XL (~18GB)
- **Port:** 4402
- **GPUs:** 0,1,2,3 (4x NVIDIA H200 NVL)
- **Context:** Up to 202,752 tokens (configured: 65,536)

## Purpose

GLM-4.7-Flash is a distilled, faster version of GLM-4.7 optimized for speed and efficiency. With only ~3.6B active parameters, it provides quick responses while maintaining strong performance on most tasks. Ideal for interactive applications and real-time inference.

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

The server provides an OpenAI-compatible API at `http://localhost:4402/v1`.

### Chat Completions

```bash
curl http://localhost:4402/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "glm-4.7-flash-q4",
    "messages": [
      {"role": "user", "content": "写一个Python函数来计算斐波那契数列"}
    ]
  }'
```

### Health Check

```bash
curl http://localhost:4402/health
```

### List Models

```bash
curl http://localhost:4402/v1/models
```

## Model Details

GLM-4.7-Flash is a lightweight Mixture-of-Experts (MoE) model designed for fast inference. Key features:

- **Fast Inference:** ~3.6B active parameters per token
- **Long Context:** Supports up to 202,752 tokens (longer than base GLM-4.7)
- **Multilingual:** Excellent Chinese and English capabilities
- **Efficient:** Optimized for real-time applications
- **Versatile:** Good for chat, completion, and instruction following

**Quantization Details:**
- UD-Q4_K_XL provides ~4-bit quantization with expert scaling
- ~18GB total model size (single file)
- Excellent quality-speed tradeoff

## GPU Memory Usage

| GPU | Usage | Approximate VRAM |
|-----|-------|------------------|
| 0   | GLM-4.7-Flash TP=4 | ~5GB |
| 1   | GLM-4.7-Flash TP=4 | ~5GB |
| 2   | GLM-4.7-Flash TP=4 | ~5GB |
| 3   | GLM-4.7-Flash TP=4 | ~5GB |

**Total:** ~18GB across 4 GPUs (significantly less than GLM-4.7)

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

- `-m /models/GLM-4.7-Flash-GGUF/GLM-4.7-Flash-UD-Q4_K_XL.gguf` - Model path
- `-ngl 99` - Offload all layers to GPU
- `-c 65536` - Context window (65K tokens, max: 202752)
- `--port 4402` - API port
- `--host 0.0.0.0` - Listen on all interfaces
- `-t 32` - 32 CPU threads
- `--jinja` - Enable Jinja template support (required for GLM)
- `--fit on` - Optimize GPU VRAM utilization
- `--temp 1.0` - Temperature sampling
- `--top-p 0.95` - Top-p sampling
- `--min-p 0.01` - Min-p sampling (recommended for GLM-4.7-Flash)
- `--repeat-penalty 1.0` - Disable repeat penalty (recommended for GLM)

### Environment Variables

- `CUDA_VISIBLE_DEVICES=0,1,2,3` - Use all 4 GPUs

## Model File

The UD-Q4_K_XL quantization is stored as a single file:
```
/data/models/GLM-4.7-Flash-GGUF/GLM-4.7-Flash-UD-Q4_K_XL.gguf (~18GB)
```

## Comparison: GLM-4.7 vs GLM-4.7-Flash

| Feature | GLM-4.7 Q2 (port 4401) | GLM-4.7-Flash Q4 (this) |
|---------|----------------------|------------------------|
| Parameters | 355B total (~52B active) | 30B total (~3.6B active) |
| Model Size | ~135GB | ~18GB |
| Speed | Slower | **Fast** |
| Max Context | 131,072 tokens | **202,752 tokens** |
| Quality | Higher | Good |
| Use Case | Complex reasoning | Interactive/real-time |

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

The model requires approximately 5GB VRAM per GPU. This is very lightweight and should run easily alongside other services.

### Port already in use

Check if port 4402 is available:
```bash
ss -tlnp | grep 4402
```

### Model not found

Ensure model file is in `/data/models/`:

```bash
ls -lh /data/models/GLM-4.7-Flash-GGUF/
```

### Slow inference

GLM-4.7-Flash is already optimized for speed. For even faster responses:

1. Reduce context size with `-c` parameter in `run.sh`
2. Use temperature 0.7-0.9 for faster, more focused responses
3. Ensure all 4 GPUs are available

## Related Services

- **GLM-4.7 Q2:** Port 4401 (higher quality, slower)
- **GLM-4.7-Flash Q4:** Port 4403 (alternative Flash instance)
- **DeepSeek V2.5 GGUF:** Port 5001 (4 GPUs)

## References

- [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)
- [GLM-4 Flash Model Card](https://huggingface.co/thudm/glm-4-9b-chat)
- [SYSTEM_CONSTRAINTS.md](../../SYSTEM_CONSTRAINTS.md)
