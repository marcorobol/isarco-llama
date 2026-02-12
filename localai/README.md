# LocalAI Server

LocalAI is an OpenAI-compatible API server that can run various models locally. It acts as a drop-in replacement for OpenAI's API, supporting multiple backends including llama.cpp.

## Overview

- **Port:** 8081
- **GPUs:** 2,3 (2x NVIDIA H200 NVL)
- **Backend:** llama-cpp (CUDA)
- **Models Config:** `localai-models.yaml`

## Purpose

LocalAI provides an OpenAI-compatible API endpoint for running GGUF models. It's ideal for:
- Drop-in OpenAI API replacement
- Applications expecting OpenAI format
- Running multiple models through a unified API
- Function calling and grammar support

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

The server provides an OpenAI-compatible API at `http://localhost:8081/v1`.

### Chat Completions

```bash
curl http://localhost:8081/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "GLM-4.7-Q8_0",
    "messages": [
      {"role": "user", "content": "Write a Python hello world"}
    ],
    "temperature": 0.7
  }'
```

### Completions

```bash
curl http://localhost:8081/v1/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "GLM-4.7-Q8_0",
    "prompt": "The sky is blue because",
    "max_tokens": 50
  }'
```

### List Models

```bash
curl http://localhost:8081/v1/models
```

## Configured Models

The server loads models from `localai-models.yaml`:

| Model | Backend | GPU Layers | Context |
|-------|---------|------------|---------|
| GLM-4.7-Q8_0 | cuda13-llama-cpp | 99 | 16384 |
| GLM-4.7-Flash-Q8_0 | llama-cpp | 99 | varies |

## Commands

| Command | Description |
|---------|-------------|
| `start` | Start the LocalAI server |
| `stop` | Stop the LocalAI server |
| `restart` | Restart the LocalAI server |
| `status` | Show server status and recent logs |
| `logs` | Show server logs (tail -f) |

## Technical Details

### Singularity Configuration

- **Image:** `localai.sif` (built from `localai.def`)
- **Runtime:** `singularity exec --nv` (NVIDIA GPU support)
- **Mounts:**
  - `/data/models:/models` (model cache)
  - `/etc/ssl/certs:/etc/ssl/certs:ro` (SSL certificates)
  - `/etc/pki:/etc/pki:ro` (PKI for HTTPS)

### Environment Variables

- `CUDA_VISIBLE_DEVICES=2,3` - Use GPUs 2 and 3

### Server Arguments

- `/local-ai run` - Run in standalone mode (no P2P)
- `--models-path=/models` - Model directory
- `--models-config-file=localai-models.yaml` - Model configuration
- `--address=0.0.0.0:8081` - Listen address and port

### CUDA MPS

The server starts CUDA MPS (Multi-Process Service) daemon to allow multiple models to share GPU resources more efficiently.

## Model Configuration

Models are defined in `localai-models.yaml`. Example configuration:

```yaml
- name: GLM-4.7-Q8_0
  backend: cuda13-llama-cpp
  parameters:
    model: GLM-4.7-Q8_0/GLM-4.7-Q8_0-00001-of-00008.gguf
    f16_kv: true
    temperature: 0.7
    top_p: 0.9
    top_k: 40
    max_tokens: 2048
  threads: 8
  context_size: 16384
  gpu_layers: 99
  template:
    use_tokenizer_template: true
  options:
    - use_jinja: true
```

## GPU Memory Usage

| GPU | Usage | Approximate VRAM |
|-----|-------|------------------|
| 2   | LocalAI models | Varies by model |
| 3   | LocalAI models | Varies by model |

Memory usage depends on:
- Model size (Q8_0 requires ~8 bytes per parameter)
- Number of loaded models
- Context size
- GPU layers offloaded

## Troubleshooting

### Server fails to start

Check logs for errors:
```bash
./run.sh logs
```

### Model not found

Ensure models exist in `/data/models/`:

```bash
ls -la /data/models/GLM-4.7-Q8_0/
ls -la /data/models/GLM-4.7-Flash-Q8_0/
```

### CUDA MPS issues

If you encounter MPS-related errors:
```bash
# Stop MPS
echo quit | nvidia-cuda-mps-control

# Restart the server
./run.sh restart
```

### Port already in use

Check if port 8081 is available:
```bash
ss -tlnp | grep 8081
```

### OpenAI Compatibility Issues

LocalAI aims for OpenAI API compatibility but may have some differences:
- Check the LocalAI documentation for specific feature support
- Ensure model is loaded before making requests
- Some advanced OpenAI features may not be supported

## Related Services

- **GLM-4.7 Q2 (llama.cpp):** Port 4401 (GPUs 0-3)
- **GLM-4.7-Flash Q4 (llama.cpp):** Port 4402 (GPUs 0-3)
- **Ollama:** Port 11434 (GPU 3)

## References

- [LocalAI GitHub](https://github.com/mudler/LocalAI)
- [LocalAI Documentation](https://localai.io/)
- [llama.cpp Backend](https://localai.io/backend/llama-cpp)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [SYSTEM_CONSTRAINTS.md](../SYSTEM_CONSTRAINTS.md)
