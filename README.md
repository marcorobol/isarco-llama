# GLM-4 with CUDA on Singularity

Complete setup for running GLM-4 models with CUDA acceleration using Singularity.

## Files

- `llamacpp-cuda-complete.sif` - Singularity image with llama.cpp + CUDA support
- `models/glm-4-9b-chat-Q5_K_M.gguf` - GLM-4-9B Chat model (6.7GB)
- `run-glm4-server.sh` - Server control script
- `docker-compose.yml` - Docker Compose configuration (for systems with Docker)

## Usage

### Option 1: Singularity (recommended for HPC)

```bash
# Start the server
./run-glm4-server.sh start

# Check status
./run-glm4-server.sh status

# View logs
./run-glm4-server.sh logs

# Stop the server
./run-glm4-server.sh stop
```

### Option 2: Direct Singularity command

```bash
singularity exec --nv -B ~/localai/models:/models \
    ~/localai/llamacpp-cuda-complete.sif \
    /opt/llama.cpp/build/bin/llama-server \
    -m /models/glm-4-9b-chat-Q5_K_M.gguf \
    -ngl 99 -c 4096 --port 8080 --host 0.0.0.0 -t 8
```

### Option 3: Docker Compose

```bash
docker-compose up -d
```

## API Endpoints

- **Health Check:** `GET http://localhost:8080/health`
- **Chat Completions:** `POST http://localhost:8080/v1/chat/completions`
- **List Models:** `GET http://localhost:8080/v1/models`

## Example Usage with curl

```bash
curl http://localhost:8080/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{
        "model": "glm-4-9b-chat",
        "messages": [{"role": "user", "content": "Hello!"}]
    }'
```

## GPU Usage

The server uses all 4 NVIDIA H200 NVL GPUs automatically. Check usage with:

```bash
nvidia-smi
./run-glm4-server.sh status
```

## Performance

- Model: GLM-4-9B-Chat (Q5_K_M quantization)
- Speed: ~186 tokens/second
- GPU Memory: ~2.5GB per GPU (total ~10GB)

## Adding More Models

1. Download GGUF models to `~/localai/models/`
2. Restart the server with the new model path

Sources:
- [Hugging Face - bartowski/glm-4-9b-chat-GGUF](https://huggingface.co/bartowski/glm-4-9b-chat-GGUF)
- [Hugging Face - zai-org/GLM-4.7-GGUF](https://huggingface.co/bartowski/zai-org_GLM-4.7-GGUF)
