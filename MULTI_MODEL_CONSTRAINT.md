# Running Multiple Models with LocalAI + Singularity

## The Constraint

When using **Singularity** with **LocalAI**, you cannot run more than one model per GPU by default. Any attempt to load a second model results in:

```
ERROR: Failed to load model
error=failed to load model with internal loader: could not load model:
rpc error: code = Unavailable desc = error reading from server: EOF
```

## Root Cause

### GPU Compute Mode: Exclusive Process

By default, NVIDIA GPUs are set to **Exclusive Process** compute mode:

```bash
$ nvidia-smi -q | grep "Compute Mode"
Compute Mode: Exclusive_Process
```

In this mode:
- **Only ONE process can access each GPU at a time**
- When the first model loads a backend process, it claims exclusive access to the GPU
- The second model's backend process is rejected by the GPU driver
- The RPC server crashes with EOF

### Why This Happens with LocalAI

LocalAI spawns **separate backend processes** for each model:
- Model 1 → `llama-cpp-rpc-server` (PID 1234) → claims GPU 2
- Model 2 → `llama-cpp-rpc-server` (PID 5678) → **rejected** by GPU 2 → EOF

---

## The Solution: CUDA MPS

**CUDA MPS (Multi-Process Service)** allows multiple processes to share a single GPU by multiplexing access through a single CUDA context.

### How MPS Works

```
Without MPS                          With MPS
─────────────                        ────────────
┌─────────┐     ┌─────────┐         ┌─────────┐
│Model 1  │     │Model 2  │         │Model 1  │
│Process  │     │Process  │         │Process  │
└────┬────┘     └────┬────┘         └────┬────┘
     │               │    X                │
     │ (rejected)    │                   │
     ▼               ▼                   ▼
┌─────────────────────────────────┐   ┌──────────┐
│ GPU 2 (Exclusive Process)     │   │   MPS    │
└─────────────────────────────────┘   └─────┬────┘
                                            │
                                            ▼
                                    ┌───────────┐
                                    │  GPU 2    │
                                    └───────────┘
```

With MPS:
1. MPS daemon creates **one shared context** on the GPU
2. Multiple backend processes connect to MPS (not the GPU directly)
3. MPS multiplexes GPU access between processes

---

## Setup Instructions

### 1. Start MPS Daemon

Before starting LocalAI, start MPS for each GPU you want to share:

```bash
# Start MPS for GPUs 2 and 3
CUDA_VISIBLE_DEVICES=2 nvidia-cuda-mps-control -d
CUDA_VISIBLE_DEVICES=3 nvidia-cuda-mps-control -d

# Verify MPS is running
ps aux | grep mps
```

### 2. Start LocalAI

```bash
cd /home/marco.robol/isarco-llama/localai
./run.sh start
```

### 3. Verify Multiple Models Work

```bash
# Load first model
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "codellama-7b", "messages": [{"role": "user", "content": "Hello"}]}'

# Load second model (should work now!)
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Codestral-22B-v0.1-Q5_K_S.gguf", "messages": [{"role": "user", "content": "Hello"}]}'
```

---

## Making MPS Permanent

The `run.sh` script has been updated to automatically start/stop MPS:

```bash
./run.sh start   # Starts MPS daemon, then LocalAI
./run.sh stop    # Stops LocalAI, then MPS daemon
./run.sh restart # Restarts both
```

### Manual MPS Management

```bash
# Start MPS manually
CUDA_VISIBLE_DEVICES=2 nvidia-cuda-mps-control -d

# Stop MPS manually
pkill -9 nvidia-cuda-mps-control
rm -rf /tmp/nvidia-mps*

# Check if MPS is running
ps aux | grep nvidia-cuda-mps-control
```

---

## Alternative Solutions

If MPS doesn't work for your use case:

### Option 1: Assign Different GPUs to Different Models

Modify `localai-models.yaml` to use specific GPUs per model:

```yaml
- name: GLM-4.7-Q8_0
  backend: cuda13-llama-cpp
  env:
    CUDA_VISIBLE_DEVICES: "2"   # Use only GPU 2
  parameters:
    model: GLM-4.7-Q8_0/GLM-4.7-Q8_0-00001-of-00008.gguf

- name: GLM-4.7-Flash-Q8_0
  backend: llama-cpp
  env:
    CUDA_VISIBLE_DEVICES: "3"   # Use only GPU 3
  parameters:
    model: GLM-4.7-Flash-Q8_0/GLM-4.7-Flash-Q8_0.gguf
```

### Option 2: Change GPU Compute Mode

Requires root access. Change from Exclusive Process to Default mode:

```bash
# Set all GPUs to Default compute mode
sudo nvidia-smi -c 3

# Verify
nvidia-smi -q | grep "Compute Mode"
# Should show: Compute Mode: Default
```

**Note**: This affects all users and processes on the system.

---

## GPU Memory Considerations

Even with MPS, models must fit in GPU memory:

| GPU | Total Memory | Model 1 | Model 2 | Remaining |
|-----|--------------|---------|----------|-----------|
| 2   | 143 GB       | 70 GB   | 70 GB    | ~3 GB     |

If models exceed GPU memory, you'll get OOM errors instead of EOF.

### Check GPU Usage

```bash
# Real-time GPU monitoring
watch -n 1 nvidia-smi

# Query memory usage
nvidia-smi --query-gpu=index,name,memory.used,memory.free --format=csv
```

---

## Troubleshooting

### Problem: Still getting EOF errors with MPS

**Check**: Is MPS actually running?

```bash
ps aux | grep nvidia-cuda-mps-control
```

**Fix**: Restart MPS and LocalAI

```bash
./run.sh stop
# Wait a few seconds
./run.sh start
```

### Problem: Models load slowly

**Cause**: MPS has overhead for context switching between processes.

**Mitigation**: Reduce `gpu_layers` in model config to use more CPU and less GPU:

```yaml
parameters:
  gpu_layers: 35  # Instead of 99
```

### Problem: MPS daemon crashes

**Check logs**:
```bash
dmesg | tail -50
```

**Common cause**: GPU hardware error or driver issue.

**Fix**: Restart GPU driver (requires root)
```bash
sudo rmmod nvidia_uvm
sudo rmmod nvidia
sudo modprobe nvidia
```

---

## References

- [NVIDIA CUDA MPS Documentation](https://docs.nvidia.com/deploy/mps/)
- [LocalAI Documentation](https://localai.io/)
- [llama.cpp GPU Offloading](https://github.com/ggerganov/llama.cpp)
