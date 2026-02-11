# SGLang with DeepSeek V2.5

This directory contains the SGLang server configuration running DeepSeek V2.5 (236B parameters).

## Requirements

### Hardware

- **GPUs:** 4x NVIDIA H200 NVL (minimum) or equivalent
- **VRAM per GPU:** ~140GB minimum per GPU
- **Total VRAM:** ~560GB for all 4 GPUs
- **Architecture:** Ampere or newer (for optimal tensor parallelism performance)

### Why 4 GPUs are Required

DeepSeek V2.5 has strict requirements due to its architecture:

1. **Tensor Parallelism (TP) Constraints:**
   - Vocabulary size: 102,400 tokens
   - TP size must evenly divide vocabulary size
   - Valid TP sizes: 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 640, 102400
   - TP=2, TP=3, TP=4 tested:
     - TP=3: ❌ Vocabulary 102400 not divisible by 3
     - TP=2: ❌ Insufficient memory (~282GB total)
     - TP=4: ✅ Works correctly (~564GB total)

2. **Memory Requirements:**
   | TP Size | Total VRAM | Per GPU VRAM | Status |
   |---------|------------|--------------|--------|
   | 1       | ~141GB     | ~141GB       | ❌ OOM  |
   | 2       | ~282GB     | ~141GB       | ❌ OOM  |
   | 3       | ~423GB     | ~141GB       | ❌ Vocab constraint |
   | 4       | ~564GB     | ~141GB       | ✅ Works |

### Software

- Apptainer/Singularity
- CUDA 12.x
- HuggingFace token for model access

## Usage

### Start the Server

```bash
./run.sh start
```

The server will:
1. Load the DeepSeek V2.5 model (this takes several minutes)
2. Start on port 30000
3. Provide OpenAI-compatible API endpoints

### Check Status

```bash
./run.sh status
```

### Stop the Server

```bash
./run.sh stop
```

### View Logs

```bash
./run.sh logs
```

## API Endpoints

- **Health Check:** `http://localhost:30000/health`
- **List Models:** `http://localhost:30000/v1/models`
- **Chat Completions:** `http://localhost:30000/v1/chat/completions`
- **Generate:** `http://localhost:30000/generate`

## Example Usage

```bash
curl http://localhost:30000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "deepseek-ai/DeepSeek-V2.5-1210",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Model Details

- **Model:** deepseek-ai/DeepSeek-V2.5-1210
- **Parameters:** 236B
- **Architecture:** Mixture-of-Experts (MoE)
- **Tensor Parallelism:** 4
- **Quantization:** Loaded from HuggingFace hub

## Files

- `run.sh` - Server management script
- `sglang.sif` - Apptainer image (lmsysorg/sglang:latest)
- `sglang-server.log` - Server logs
- `sglang-server.pid` - Process ID file
