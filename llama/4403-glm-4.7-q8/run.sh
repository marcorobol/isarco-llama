#!/bin/bash
# Startup script for GLM-4.7 llama-server
# Usage: ./run.sh [start|stop|restart|status|logs]
#
# GLM-4.7 models require specific flags for proper operation:
#   --jinja          - Required for correct chat template handling
#   --fit on         - Optimize GPU utilization across all available VRAM
#   --repeat-penalty 1.0 - Disable repeat penalty (recommended for GLM models)
#   --min-p 0.01     - Additional parameter for GLM-4.7-Flash
#
# Recommended quantizations:
#   - GLM-4.7: UD-Q2_K_XL (smaller, faster) or Q4_K_XL (better quality)
#   - GLM-4.7-Flash: UD-Q4_K_XL
#
# With 575GB VRAM, you can use very large contexts (up to 131072 for GLM-4.7)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIF="$SCRIPT_DIR/../shared/llamacpp-cuda-complete.sif"

# Model configuration - change this to switch between models
# Options: GLM-4.7-Flash-UD-Q4_K_XL.gguf, GLM-4.7-UD-Q2_K_XL.gguf, etc.
MODEL_DIR="/data/models"
MODEL_NAME="GLM-4.7-Flash-UD-Q4_K_XL.gguf"
MODEL="$MODEL_DIR/$MODEL_NAME"

HOST="0.0.0.0"
PORT=4403
GPU_DEVICES="0,1,2,3"  # GPUs to use (comma-separated, e.g., "0,1,2,3" or "0" for single GPU)
NGP_LAYERS=99
CTX_SIZE=65536  # Increased from 4096 - GLM-4.7-Flash supports up to 202752, GLM-4.7 up to 131072
THREADS=32       # Increased to better utilize hardware
PIDFILE="$SCRIPT_DIR/llama-server.pid"
LOGFILE="$SCRIPT_DIR/llama-server.log"

# Generation parameters (Z.ai recommended)
TEMP=1.0
TOP_P=0.95
MIN_P=0.01      # Recommended for GLM-4.7-Flash
REPEAT_PENALTY=1.0  # Disable repeat penalty (recommended)

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

start_server() {
    if check_server; then
        echo -e "${YELLOW}Server is already running (PID: $(cat $PIDFILE))${NC}"
        return 1
    fi

    echo -e "${GREEN}Starting GLM-4.7 llama-server...${NC}"
    echo "Model: $MODEL"
    echo "Port: $PORT"

    cd "$SCRIPT_DIR"
    nohup singularity exec --nv -B "/data/models:/models" \
        --env "CUDA_VISIBLE_DEVICES=$GPU_DEVICES" \
        "$SIF" \
        /opt/llama.cpp/build/bin/llama-server \
        -m "/models/$MODEL_NAME" \
        -ngl $NGP_LAYERS \
        -c $CTX_SIZE \
        --port $PORT \
        --host "$HOST" \
        -t $THREADS \
        --jinja \
        --fit on \
        --temp $TEMP \
        --top-p $TOP_P \
        --min-p $MIN_P \
        --repeat-penalty $REPEAT_PENALTY \
        > "$LOGFILE" 2>&1 &

    echo $! > "$PIDFILE"

    # Wait for server to be ready
    echo "Waiting for server to start..."
    for i in {1..30}; do
        if curl -s "http://localhost:$PORT/health" > /dev/null 2>&1; then
            echo -e "${GREEN}Server started successfully!${NC}"
            echo "API: http://localhost:$PORT"
            echo "Logs: $LOGFILE"
            return 0
        fi
        sleep 2
    done

    echo -e "${RED}Server failed to start. Check logs at $LOGFILE${NC}"
    return 1
}

stop_server() {
    if ! check_server; then
        echo -e "${YELLOW}Server is not running${NC}"
        return 1
    fi

    PID=$(cat "$PIDFILE")
    echo -e "${GREEN}Stopping server (PID: $PID)...${NC}"
    kill $PID
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
    kill -9 $PID
    rm -f "$PIDFILE"
}

status_server() {
    if check_server; then
        PID=$(cat "$PIDFILE")
        echo -e "${GREEN}Server is running (PID: $PID)${NC}"

        # Show GPU usage
        echo ""
        echo "GPU Usage:"
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader

        # Show health
        if curl -s "http://localhost:$PORT/health" > /dev/null 2>&1; then
            echo -e "${GREEN}Health: OK${NC}"
        else
            echo -e "${RED}Health: FAILED${NC}"
        fi

        echo ""
        echo "API Endpoints:"
        echo "  - Health: http://localhost:$PORT/health"
        echo "  - Chat: http://localhost:$PORT/v1/chat/completions"
        echo "  - Models: http://localhost:$PORT/v1/models"

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
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
