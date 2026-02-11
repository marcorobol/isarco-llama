# DeepSeek V2.5 GGUF Q6_K

236B parameter model running via llama.cpp with Q6_K quantization.

## Model Details

- **Model:** lmstudio-community/DeepSeek-V2.5-GGUF
- **Quantization:** Q6_K (~193GB total)
- **Port:** 5001
- **GPUs:** 0,1 (tensor split across 2 GPUs)
- **Context:** 8192 tokens (adjustable)

## GPU Memory Usage

- **GPU 0:** ~97GB VRAM
- **GPU 1:** ~96GB VRAM
- **Total:** ~193GB

## Usage

### Download Model (First Time Only)

```bash
./download.sh
```

This will download ~193GB of model files (5 split files). The download may take several hours depending on your connection speed.

### Start Server
```bash
./run.sh start
```

**Note:** The model must be downloaded first using `./download.sh` before starting the server.

### Stop Server
```bash
./run.sh stop
```

### Check Status
```bash
./run.sh status
```

### View Logs
```bash
./run.sh logs
```

## API Endpoints

- **Health:** http://localhost:5001/health
- **Chat Completions:** http://localhost:5001/v1/chat/completions
- **Models:** http://localhost:5001/v1/models
- **Web UI:** http://localhost:5001 (built-in llama-server UI)

## Example Request

```bash
curl http://localhost:5001/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "deepseek-v2.5-gguf",
    "messages": [{"role": "user", "content": "Write a Python function to sort an array"}],
    "max_tokens": 512
  }'
```

## Comparison with SGLang Version

This GGUF version runs on 2 GPUs instead of 4, freeing up GPU 2-3 for other models.

| Feature | GGUF Q6_K (this) | SGLang (port 30000) |
|---------|------------------|---------------------|
| GPUs Required | 2 | 4 |
| Quantization | 6-bit | FP16/FP8 |
| Memory Usage | ~193GB | ~544GB |
| Quality | Very high (6-bit) | Full precision |

## Troubleshooting

### Model download fails

If the download script fails:

1. Check your internet connection
2. Ensure you have enough disk space (~200GB)
3. Model files are stored in `/data/models/DeepSeek-V2.5-GGUF/Q6_K/`
4. You can resume interrupted downloads by running `./download.sh` again

### Out of memory

If the model doesn't fit on GPUs 0-1:

1. Stop any conflicting services on those GPUs
2. Try a smaller quantization (Q4_K_M instead of Q6_K)
3. Reduce context size with `-c` parameter

### Server won't start

Check logs:
```bash
tail -f llama-server.log
```

Common issues:
- GPU memory already in use (stop conflicting services)
- Port 5001 already in use
- Missing CUDA libraries (ensure `--nv` flag is used)

## Configuration

Edit `run.sh` to adjust:

- **CTX_SIZE:** Context window (default: 8192, max depends on memory)
- **TEMP:** Temperature (default: 1.0)
- **TOP_P:** Top-p sampling (default: 0.95)
- **GPU_DEVICES:** Which GPUs to use (default: "0,1")
- **NGPUS:** Number of GPUs for tensor split (default: 2)
