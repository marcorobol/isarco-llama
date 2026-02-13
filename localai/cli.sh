#!/bin/bash
# CLI wrapper for LocalAI commands
# Usage: ./cli.sh [local-ai command and arguments]
# Examples:
#   ./cli.sh models list
#   ./cli.sh models install huggingface://TheBloke/phi-2-GGUF
#   ./cli.sh run huggingface://TheBloke/phi-2-GGUF/phi-2.Q8_0.gguf

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIF="$SCRIPT_DIR/localai.sif"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if container exists
if [ ! -f "$SIF" ]; then
    echo -e "${RED}Error: Singularity image not found: $SIF${NC}"
    echo "Please build the image first with:"
    echo "  singularity build --remote localai.sif localai.def"
    exit 1
fi

# Singularity exec options (same as run.sh)
SINGULARITY_OPTS=(
    --nv
    --env CUDA_VISIBLE_DEVICES=2,3
    --env MODELS_PATH=/models
    -B "/data/models:/models"
    -B /etc/ssl/certs:/etc/ssl/certs:ro
    -B /etc/pki:/etc/pki:ro
    -B "/data/models/huggingface:/root/.cache/huggingface" \
    --env "HF_TOKEN=$HF_TOKEN" \
    --env "PYTHONUNBUFFERED=1" \
    --env "HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface" \
)

# Run local-ai CLI with provided arguments
# singularity exec "${SINGULARITY_OPTS[@]}" "$SIF" /local-ai "$@"
singularity exec "${SINGULARITY_OPTS[@]}" "$SIF" bash
