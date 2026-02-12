# GLM-4.7-Flash UD-Q4_K_XL - llama.cpp Server (Instance 2)

30B parameter Mixture-of-Experts (MoE) Flash model running via llama.cpp with UD-Q4_K_XL quantization. This is the second instance of GLM-4.7-Flash.

## Overview

- **Model:** GLM-4.7-Flash (30B MoE, ~3.6B active parameters)
- **Quantization:** UD-Q4_K_XL (~18GB)
- **Port:** 4403
- **GPUs:** 0,1,2,3 (4x NVIDIA H200 NVL)
- **Context:** Up to 202,752 tokens (configured: 65,536)

## Purpose

This is a secondary instance of GLM-4.7-Flash running on port 4403. It provides the same fast, efficient inference as port 4402, allowing for multiple concurrent deployments or A/B testing scenarios.

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

The server provides an OpenAI-compatible API at `http://localhost:4403/v1`.

### Chat Completions

```bash
curl http://localhost:4403/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "glm-4.7-flash-q8",
    "messages": [
      {"role": "user", "content": "写一个Python函数来计算斐波那契数列"}
    ]
  }'
```

### Health Check

```bash
curl http://localhost:4403/health
```

### List Models

```bash
curl http://localhost:4403/v1/models
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

**Total:** ~18GB across 4 GPUs

**Note:** Running both Flash instances (4402 and 4403) simultaneously would require ~36GB VRAM total.

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

- `-m /models/GLM-4.7-Flash-UD-Q4_K_XL.gguf` - Model path
- `-ngl 99` - Offload all layers to GPU
- `-c 65536` - Context window (65K tokens, max: 202752)
- `--port 4403` - API port
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
/data/models/GLM-4.7-Flash-UD-Q4_K_XL.gguf (~18GB)
```

Note: Both instances (4402 and 4403) share the same model file.

## Instance Comparison

| Feature | Port 4401 | Port 4402 | Port 4403 (this) |
|---------|-----------|-----------|------------------|
| Model | GLM-4.7 Q2 | GLM-4.7-Flash Q4 | GLM-4.7-Flash Q4 |
| Parameters | 355B (~52B active) | 30B (~3.6B active) | 30B (~3.6B active) |
| Model Size | ~135GB | ~18GB | ~18GB |
| Speed | Slow | Fast | Fast |
| Max Context | 131,072 | 202,752 | 202,752 |
| Quality | Higher | Good | Good |

## Troubleshooting

### Server fails to start

Check logs for errors:
```bash
./run.sh logs
```

### Port already in use

Check if port 4403 is available:
```bash
ss -tlnp | grep 4403
```

If you want to run both Flash instances (4402 and 4403) simultaneously, ensure sufficient GPU memory is available (~36GB total).

### Model not found

Ensure model file is in `/data/models/`:

```bash
ls -lh /data/models/GLM-4.7-Flash-GGUF/
```

### Running Multiple Instances

To run both Flash instances simultaneously:

1. Start instance 4402: `cd ../4402-glm-4.7-flash-q4 && ./run.sh start`
2. Start instance 4403: `cd ../4403-glm-4.7-q8 && ./run.sh start`
3. Verify both are running: `./run.sh status` in each directory

## Related Services

- **GLM-4.7 Q2:** Port 4401 (higher quality, slower)
- **GLM-4.7-Flash Q4:** Port 4402 (same model, different port)
- **DeepSeek V2.5 GGUF:** Port 5001 (4 GPUs)

## References

- [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)
- [GLM-4 Flash Model Card](https://huggingface.co/thudm/glm-4-9b-chat)
- [SYSTEM_CONSTRAINTS.md](../../SYSTEM_CONSTRAINTS.md)
