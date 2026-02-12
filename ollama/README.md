# Ollama Server

Ollama is a user-friendly platform for running and managing large language models locally. This server provides a simple API for model inference on GPU 3.

## Overview

- **Port:** 11434
- **GPU:** 3 (NVIDIA H200 NVL)
- **Max Loaded Models:** 6
- **Data Directory:** `/data/models/.ollama`
- **Image:** `ollama/ollama` (Singularity SIF)

## Purpose

Ollama provides an easy-to-use interface for running various open-source models. It's ideal for:
- Quick model testing and experimentation
- Interactive chat sessions
- Simple API integration
- Model management (pull, run, list)

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

## Model Management

### Pull a Model

```bash
# Pull a specific model
./run.sh pull llama2
./run.sh pull mistral
./run.sh pull codellama
```

### Run a Model Interactively

```bash
# Start an interactive chat session
./run.sh run llama2
./run.sh run mistral
```

### List Available Models

Visit the [Ollama Model Library](https://ollama.com/library) to see all available models.

## API Usage

The server provides a REST API at `http://localhost:11434/api`.

### Generate (Chat/Completion)

```bash
curl http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama2",
    "prompt": "Why is the sky blue?",
    "stream": false
  }'
```

### Chat Endpoint

```bash
curl http://localhost:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama2",
    "messages": [
      {"role": "user", "content": "Why is the sky blue?"}
    ],
    "stream": false
  }'
```

### List Installed Models

```bash
curl http://localhost:11434/api/tags
```

### Show Model Information

```bash
curl http://localhost:11434/api/show \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "llama2"
  }'
```

## Commands

| Command | Description |
|---------|-------------|
| `start` | Start the Ollama server |
| `stop` | Stop the Ollama server |
| `restart` | Restart the Ollama server |
| `status` | Show server status and installed models |
| `logs` | Show server logs (tail -f) |
| `run <model>` | Run a model interactively |
| `pull <model>` | Download a model |

## Technical Details

### Singularity Configuration

- **Image:** `ollama/ollama` (Singularity SIF at `ollama.sif`)
- **Runtime:** `singularity exec --nv` (NVIDIA GPU support)
- **Mounts:**
  - `/data/models/.ollama:/root/.ollama` (models and data)
  - `/etc/ssl/certs:/etc/ssl/certs:ro` (SSL certificates)
  - `/etc/pki:/etc/pki:ro` (PKI for HTTPS)

### Environment Variables

- `CUDA_VISIBLE_DEVICES=3` - Use GPU 3 only
- `OLLAMA_MODELS=/root/.ollama/models` - Models directory
- `OLLAMA_NUM_GPU=1` - Number of GPUs to use
- `OLLAMA_MAX_LOADED_MODELS=6` - Maximum models to keep in memory
- `GGML_CUDA_ENABLE_UNIFIED_MEMORY=1` - Enable unified memory for CUDA

### Server Arguments

- `serve` - Start the Ollama server (listens on 0.0.0.0:11434)

## Popular Models

Some popular models available through Ollama:

| Model | Description | Size |
|-------|-------------|------|
| `llama2` | Meta Llama 2 | ~3.8GB |
| `mistral` | Mistral 7B | ~4.1GB |
| `codellama` | Code Llama | ~3.8GB |
| `phi` | Microsoft Phi-2 | ~1.7GB |
| `gemma` | Google Gemma | ~2.0GB |
| `qwen` | Alibaba Qwen | varies |

## GPU Memory Usage

| GPU | Usage | Approximate VRAM |
|-----|-------|------------------|
| 3   | Ollama (varies by model) | Depends on loaded models |

Typical model memory requirements:
- Small models (2-7B): ~4-8GB per model
- Medium models (13-34B): ~16-26GB per model
- Large models (70B+): ~40GB+ per model

## Troubleshooting

### Server fails to start

Check logs for errors:
```bash
./run.sh logs
```

### Model download fails

If a model pull fails:

1. Check internet connectivity
2. Ensure sufficient disk space in `/data/models/.ollama`
3. Try again - Ollama supports resume for interrupted downloads

### Out of memory

If GPU 3 runs out of memory:

1. Reduce `OLLAMA_MAX_LOADED_MODELS` in `run.sh`
2. Stop unused models: Ollama automatically unloads models when needed
3. Use smaller quantized versions of models

### Port already in use

Check if port 11434 is available:
```bash
ss -tlnp | grep 11434
```

### Interactive `run` command doesn't work

The `run` command connects to the server. Ensure:
1. Server is running: `./run.sh status`
2. Model is installed: `curl http://localhost:11434/api/tags`

## Related Services

- **GLM-4.7 Q2:** Port 4401 (GPUs 0-3)
- **GLM-4.7-Flash Q4:** Port 4402 (GPUs 0-3)
- **GLM-4.7-Flash Q4:** Port 4403 (GPUs 0-3)
- **DeepSeek V2.5 GGUF:** Port 5001 (GPUs 0-1)

## References

- [Ollama Website](https://ollama.com)
- [Ollama GitHub](https://github.com/ollama/ollama)
- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Ollama Model Library](https://ollama.com/library)
- [SYSTEM_CONSTRAINTS.md](../SYSTEM_CONSTRAINTS.md)
