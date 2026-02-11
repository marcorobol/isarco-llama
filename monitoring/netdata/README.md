# Netdata Monitoring (Singularity/Apptainer)

This directory contains the Netdata monitoring setup for the isarco-llama server using Singularity/Apptainer instead of Docker. Netdata provides real-time monitoring of system metrics, GPU statistics, and application-level metrics for the LLM inference services.

## Requirements

- **Singularity** or **Apptainer** (the script auto-detects which is available)
- No sudo/root privileges required

## Quick Start

```bash
# Start Netdata
./run.sh start

# Check status
./run.sh status

# View logs
./run.sh logs

# Stop Netdata
./run.sh stop
```

## Dashboard Access

After starting, Netdata is available at:

| Access Method | URL |
|--------------|-----|
| **Local** | http://localhost:19999 |
| **Remote** | http://isarco01.disi.unitn.it:19999 |
| **Netdata Cloud** | Via claim token (configured in `.env`) |

## Configuration

### Environment Variables

Add the following to `/home/marco.robol/isarco-llama/.env`:

```bash
# Netdata Cloud claim token (optional)
# Get this from https://app.netdata.cloud
NETDATA_CLAIM_TOKEN="your-claim-token-here"
```

### How It Works

The script uses Singularity/Apptainer to:

1. **Pull the Docker image** and convert it to SIF format (cached locally as `netdata.sif`)
2. **Run without root** - Singularity runs in user namespace
3. **Bind mount system paths** for monitoring access (read-only)
4. **Run in background** with logs stored in `logs/netdata.log`

### Bind Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `/` | `/host/root:ro` | Root filesystem (read-only) |
| `/proc` | `/host/proc:ro` | Process information |
| `/sys` | `/host/sys:ro` | System information |
| `/etc/passwd` | `/host/etc/passwd:ro` | User information |
| `/etc/group` | `/host/etc/group:ro` | Group information |
| `/var/run/dbus/system_bus_socket` | `/var/run/dbus/system_bus_socket:ro` | D-Bus for system stats |

## Monitoring Capabilities

### System Metrics
- CPU usage (per-core and overall)
- Memory utilization
- Disk I/O and filesystem usage
- Network traffic and connections
- System load averages

### GPU Monitoring
- NVIDIA GPU utilization (via nvidia-smi)
- GPU memory usage
- GPU temperature
- GPU power consumption

### Application Monitoring
- SGLang server processes
- System process statistics
- Custom application metrics

## Commands

| Command | Description |
|---------|-------------|
| `./run.sh start` | Start Netdata (auto-pulls SIF if needed) |
| `./run.sh stop` | Stop Netdata |
| `./run.sh restart` | Restart Netdata |
| `./run.sh status` | Show status, health, and URLs |
| `./run.sh logs` | View logs (live tail) |
| `./run.sh update` | Pull latest image and restart |
| `./run.sh pull` | Only pull/update the SIF image |
| `./run.sh shell` | Start interactive shell for debugging |

## Files Created

| File | Description |
|------|-------------|
| `netdata.sif` | Singularity image file (pulled from Docker Hub) |
| `netdata.pid` | Process ID file |
| `logs/netdata.log` | Console output logs |
| `state/` | Writable state directory (cache, lib, log, config) |

## Troubleshooting

### Port already in use

Check if port 19999 is already in use:
```bash
lsof -i :19999
# or
ss -tlnp | grep 19999
```

### GPU metrics not visible

Verify nvidia-smi is working:
```bash
nvidia-smi
```

### Dashboard not accessible

1. Check if Netdata is running:
   ```bash
   ./run.sh status
   ```

2. Check the logs:
   ```bash
   ./run.sh logs
   ```

3. Test locally:
   ```bash
   curl -I http://localhost:19999
   ```

### Permission issues with bind mounts

If you see permission errors accessing certain paths, you may need to adjust the bind mount options or check file permissions on the host.

### Cloud connection issues

Verify the claim token is set in `.env`:
```bash
grep NETDATA_CLAIM_TOKEN /home/marco.robol/isarco-llama/.env
```

Check logs for claim errors:
```bash
./run.sh logs | grep -i claim
```

## Key Differences from Docker

| Docker | Singularity/Apptainer |
|--------|----------------------|
| Runs as daemon | Runs as regular process |
| Requires root for many ops | No root required |
| `docker run` | `singularity exec` |
| Container names | Process tracking via PID file |
| `docker logs` | Log file in `logs/` directory |
| Images cached by daemon | SIF file stored locally |

## Verification

After deployment, verify the monitoring setup:

```bash
# 1. Check Netdata is running
./run.sh status

# 2. Verify dashboard is accessible
curl -I http://localhost:19999

# 3. Check GPU metrics collection
nvidia-smi

# 4. View logs for any errors
./run.sh logs
```

## Resources

- [Netdata Documentation](https://learn.netdata.cloud/)
- [Netdata Cloud](https://app.netdata.cloud)
- [Singularity Documentation](https://sylabs.io/docs/)
- [Apptainer Documentation](https://apptainer.org/docs/)
