# System Constraints and Limits

**Machine:** isarco01.disi.unitn.it
**Last Updated:** 2025-02-11

## Access Constraints

### No sudo Access
- Cannot perform privileged operations
- Cannot install system packages
- Must use user-level solutions

### No Docker
- Docker daemon not accessible
- **Alternative:** Use Singularity/Apptainer
- Singularity version: Apptainer 1.4.5-2

### SSL Certificates in Singularity
For any HTTPS operations inside Singularity containers, must mount:

```bash
-B /etc/ssl/certs:/etc/ssl/certs:ro \
-B /etc/pki:/etc/pki:ro
```

**Example:**
```bash
singularity exec --nv \
    -B /etc/ssl/certs:/etc/ssl/certs:ro \
    -B /etc/pki:/etc/pki:ro \
    image.sif \
    command
```

## Hardware Limits

### GPUs
- **Model:** 4x NVIDIA H200 NVL
- **VRAM per GPU:** ~143GB
- **Total VRAM:** ~575GB
- **CUDA Version:** 13.1
- **Compute Capability:** 9.0

### Memory
- Each GPU can hold ~140-150GB when running large models
- GPU utilization: ~95% during inference

### Storage
- **/data partition:** 3.5TB total
- **Available:** ~2.5TB (as of 2025-02-11)
- **Models directory:** `/data/models/`
- **Disk usage:** 1004GB used (29%)

## Network Limits

### Ports
- Must avoid port conflicts with existing services
- Current allocations:
  - 30000: SGLang DeepSeek V2.5
  - 4401: GLM-4.7 Q2
  - 4402: GLM-4.7-Flash Q4
  - 4403: GLM-4.7 Q8
  - 5001: DeepSeek V2.5 GGUF
  - 11434: Ollama

### Bandwidth
- HuggingFace downloads can be slow
- Large models (~200GB) may take several hours

## Model Size Constraints

### Current GPU Allocation (as of 2025-02-11)

| GPU | Model | Size | Remaining |
|-----|-------|------|-----------|
| 0 | DeepSeek V2.5 GGUF Q6_K | ~97GB | ~43GB |
| 1 | DeepSeek V2.5 GGUF Q6_K | ~96GB | ~44GB |
| 2 | GLM-4.7 Q2 | ~135GB | ~5GB |
| 3 | Ollama (available) | 0GB | ~140GB |

### Maximum Model Sizes by Quantization

Reference for planning future model deployments:

| Model | Params | Q2 | Q4 | Q6 | Q8 |
|-------|--------|----|----|----|-----|
| DeepSeek V2.5 | 236B | ~47GB | ~62GB | ~93GB | ~124GB |
| DeepSeek V2.5 GGUF | 236B | - | ~142GB | ~193GB | ~256GB |
| GLM-4.7 | 355B | ~135GB | - | - | ~250GB |
| GLM-4.7-Flash | 30B | - | ~18GB | - | ~36GB |
| DeepSeek-Coder V2 | 16B | ~8GB | ~16GB | ~24GB | ~32GB |
| Codestral | 22B | ~10GB | ~20GB | ~30GB | ~44GB |
| Llama 3.2 | 3B | ~1.5GB | ~2GB | ~2.5GB | ~3GB |

## Singularity Constraints

### Container Images
- Shared image location: `llama/shared/llamacpp-cuda-complete.sif`
- Image size: ~4.7GB
- Cannot rebuild without sudo (requires fakeroot or remote build)

### Build Options (without sudo)
1. **Remote build:** Use Singularity remote builder
2. **Fakeroot:** If available (check with `singularity build --help`)
3. **Pre-built images:** Pull from Docker Hub: `singularity pull image.sif docker://...`

### GPU Support
Always use `--nv` flag for GPU access:
```bash
singularity exec --nv image.sif command
```

### Environment Variables
Set in singularity with `--env`:
```bash
--env CUDA_VISIBLE_DEVICES=0,1 \
--env OLLAMA_NUM_GPU=1
```

### Bind Mounts
Use `-B` for directory access:
```bash
-B /data/models:/models \
-B /etc/ssl/certs:/etc/ssl/certs:ro
```

## Performance Characteristics

### Generation Speed
- GLM-4.7: ~186 tokens/second
- Memory per GPU: ~2.5GB for context
- GPU utilization: ~95% during generation

### Inference Optimization
- Full GPU offload: `-ngl 99` (all layers to GPU)
- Tensor split for multi-GPU: `-ts N` (split across N GPUs)
- Flash Attention: `--flash-attn on` (if supported)

## Common Pitfalls

### 1. HTTPS in Singularity
**Problem:** "HTTPS is not supported"
**Solution:** Mount SSL certificates:
```bash
-B /etc/ssl/certs:/etc/ssl/certs:ro \
-B /etc/pki:/etc/pki:ro
```

### 2. CUDA Library Missing
**Problem:** "libcuda.so.1: cannot open shared object file"
**Solution:** Add `--nv` flag to singularity exec

### 3. GPU Memory Exceeded
**Problem:** OOM (Out of Memory) errors
**Solutions:**
- Use smaller quantization (Q4 instead of Q8)
- Split across more GPUs with `-ts`
- Reduce context size `-c`

### 4. Port Already in Use
**Problem:** "Address already in use"
**Solution:** Check with `lsof -i :PORT` and stop conflicting service

### 5. Permission Denied
**Problem:** Cannot write to directories
**Solution:** Check ownership with `ls -la`, use user-writable locations

## File Locations

### Models
- Base path: `/data/models/`
- GLM-4.7: `/data/models/GLM-4.7-GGUF/`
- DeepSeek GGUF: `/data/models/DeepSeek-V2.5-GGUF/`
- Ollama: `/data/models/.ollama/`

### Configurations
- Project root: `/home/marco.robol/isarco-llama/`
- llama.cpp services: `/home/marco.robol/isarco-llama/llama/`
- SGLang services: `/home/marco.robol/isarco-llama/sglang/`
- Ollama: `/home/marco.robol/isarco-llama/ollama/`

### Singularity Images
- Shared: `/home/marco.robol/isarco-llama/llama/shared/llamacpp-cuda-complete.sif`
- Ollama: `/home/marco.robol/isarco-llama/ollama/ollama.sif`

## Quick Reference Commands

### Check GPU Status
```bash
nvidia-smi
nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv
```

### Check Disk Space
```bash
df -h /data
du -sh /data/models/*
```

### Check Running Services
```bash
ps aux | grep -E 'llama-server|ollama|sglang'
lsof -i :4401  # Check specific port
```

### Kill Hung Process
```bash
kill <PID>
kill -9 <PID>  # Force kill
```

### Monitor Logs
```bash
tail -f /path/to/service/llama-server.log
```

## Best Practices

1. **Always check GPU availability** before starting new services
2. **Use tensor split** (`-ts`) for models >140GB
3. **Monitor downloads** - large files can take hours
4. **Test with small models first** before deploying large ones
5. **Keep README files updated** in each service directory
6. **Use version control** for configuration scripts (git repo)
7. **Document port allocations** to avoid conflicts
8. **Clean up old PID files** if processes crash
