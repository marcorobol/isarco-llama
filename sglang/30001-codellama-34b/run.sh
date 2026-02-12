#!/bin/bash
# Startup script for SGLang server with CodeLlama 34B Instruct using Apptainer

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../.env"

# Configuration
HOST="0.0.0.0"
PORT=30001
PIDFILE="$SCRIPT_DIR/sglang-server.pid"
LOGFILE="$SCRIPT_DIR/sglang-server.log"
MODEL_PATH="codellama/CodeLlama-34b-Instruct-hf"
DATA_DIR="/data/models/huggingface"
SIF="$SCRIPT_DIR/../shared/sglang.sif"
DOCKER_IMAGE="docker://lmsysorg/sglang:latest"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_server() {
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

pull_image() {
    echo -e "${GREEN}Pulling SGLang Apptainer image...${NC}"
    apptainer pull "$SIF" "$DOCKER_IMAGE"
    echo -e "${GREEN}Image pulled successfully${NC}"
}

start_server() {
    if check_server; then
        echo -e "${YELLOW}Server is already running (PID: $(cat $PIDFILE))${NC}"
        return 1
    fi

    echo -e "${GREEN}Starting SGLang server with CodeLlama 34B Instruct...${NC}"
    echo "Model: $MODEL_PATH"
    echo "Port: $PORT"
    echo "GPUs: 0,1 (TP=2)"
    echo "HuggingFace cache: $DATA_DIR"
    echo "Log file: $LOGFILE"

    # Ensure data directory exists
    mkdir -p "$DATA_DIR"

    cd "$SCRIPT_DIR"

    # Pull SIF image if it doesn't exist
    if [ ! -f "$SIF" ]; then
        pull_image
    fi

    # Start the server with Apptainer (GPU 0+1 with TP=2)
    apptainer run --nv \
        -B "$DATA_DIR:/root/.cache/huggingface" \
        -B /etc/ssl/certs:/etc/ssl/certs:ro \
        -B /etc/pki:/etc/pki:ro \
        --env "HF_TOKEN=$HF_TOKEN" \
        --env "PYTHONUNBUFFERED=1" \
        --env "HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface" \
        --env "CUDA_VISIBLE_DEVICES=0,1" \
        "$SIF" \
        python3 -m sglang.launch_server \
            --model-path "$MODEL_PATH" \
            --host 0.0.0.0 \
            --port 30001 \
            --tp 2 \
        > "$LOGFILE" 2>&1 &

    echo $! > "$PIDFILE"

    # Wait for server to be ready
    echo "Waiting for server to start (this may take a while for model loading)..."
    local max_wait=300  # 5 minutes
    local waited=0

    while [ $waited -lt $max_wait ]; do
        if curl -s "http://localhost:$PORT/health" > /dev/null 2>&1 || \
           curl -s "http://localhost:$PORT/v1/models" > /dev/null 2>&1; then
            echo -e "${GREEN}Server started successfully!${NC}"
            echo "API: http://localhost:$PORT"
            echo "Health: http://localhost:$PORT/health"
            echo "OpenAI-compatible API: http://localhost:$PORT/v1"
            echo ""
            echo "Test with:"
            echo "  curl http://localhost:$PORT/v1/chat/completions \\"
            echo "    -H 'Content-Type: application/json' \\"
            echo "    -d '{\"model\": \"$MODEL_PATH\", \"messages\": [{\"role\": \"user\", \"content\": \"Write a Python hello world\"}]}'"
            return 0
        fi
        sleep 5
        waited=$((waited + 5))
        echo -n "."
    done

    echo ""
    echo -e "${YELLOW}Server is starting but health check not yet passed. Check logs: $LOGFILE${NC}"
    return 0
}

stop_server() {
    if ! check_server; then
        echo -e "${YELLOW}Server is not running${NC}"
        return 1
    fi

    PID=$(cat "$PIDFILE")
    echo -e "${GREEN}Stopping server (PID: $PID)...${NC}"

    kill $PID 2>/dev/null || true
    rm -f "$PIDFILE"

    # Wait for process to end
    for i in {1..10}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            echo -e "${GREEN}Server stopped${NC}"
            return 0
        fi
        sleep 1
    done

    echo -e "${YELLOW}Force killing server...${NC}"
    kill -9 $PID 2>/dev/null || true
    rm -f "$PIDFILE"
}

status_server() {
    if check_server; then
        PID=$(cat "$PIDFILE")
        echo -e "${GREEN}Server is running (PID: $PID)${NC}"

        # Show GPU usage
        echo ""
        echo "GPU Usage:"
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "GPU info not available"

        # Show health
        echo ""
        if curl -s "http://localhost:$PORT/v1/models" > /dev/null 2>&1; then
            echo -e "${GREEN}API: Ready${NC}"
            curl -s "http://localhost:$PORT/v1/models" | jq '.data[] | {id: .id, object: .object}' 2>/dev/null || echo "Model info available"
        else
            echo -e "${YELLOW}API: Still loading...${NC}"
        fi

        echo ""
        echo "API Endpoints:"
        echo "  - Health:        http://localhost:$PORT/health"
        echo "  - List Models:   http://localhost:$PORT/v1/models"
        echo "  - Chat (OpenAI): http://localhost:$PORT/v1/chat/completions"
        echo "  - Generate:      http://localhost:$PORT/generate"

        return 0
    else
        echo -e "${RED}Server is not running${NC}"
        return 1
    fi
}

logs_server() {
    if [ -f "$LOGFILE" ]; then
        tail -f "$LOGFILE"
    else
        echo -e "${YELLOW}No log file found${NC}"
    fi
}

pull_model() {
    echo -e "${GREEN}Pulling CodeLlama 34B Instruct model to $DATA_DIR...${NC}"
    echo "This will download approximately 64GB of data."

    mkdir -p "$DATA_DIR"

    # Pull SIF image if needed
    if [ ! -f "$SIF" ]; then
        pull_image
    fi

    # Use huggingface-cli to download the model
    apptainer run --nv \
        -B "$DATA_DIR:/root/.cache/huggingface" \
        --env "HF_TOKEN=$HF_TOKEN" \
        --env "HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface" \
        "$SIF" \
        huggingface-cli download "$MODEL_PATH" \
            --local-dir /data/models/codellama-34b-instruct \
            --local-dir-use-symlinks False \
            --repo-type model
}

case "${1:-start}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 2
        start_server
        ;;
    status)
        status_server
        ;;
    logs)
        logs_server
        ;;
    pull)
        pull_model
        ;;
    pull-image)
        pull_image
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|pull|pull-image}"
        echo ""
        echo "Commands:"
        echo "  start       - Start the SGLang server"
        echo "  stop        - Stop the SGLang server"
        echo "  restart     - Restart the SGLang server"
        echo "  status      - Show server status and GPU usage"
        echo "  logs        - Show server logs"
        echo "  pull        - Pull the CodeLlama 34B Instruct model"
        echo "  pull-image  - Pull the SGLang Apptainer image"
        exit 1
        ;;
esac
