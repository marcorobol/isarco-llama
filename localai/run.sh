#\!/bin/bash
# Startup script for LocalAI standalone server
# Usage: ./run.sh [start|stop|restart|status|logs]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIF="$SCRIPT_DIR/localai.sif"
MODELS_YAML="$SCRIPT_DIR/localai-models.yaml"
MODELS_DIR="/data/models"
HOST="0.0.0.0"
PORT=8081
PIDFILE="$SCRIPT_DIR/localai.pid"
LOGFILE="$SCRIPT_DIR/localai.log"

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
        echo -e "${YELLOW}LocalAI server is already running (PID: $(cat $PIDFILE))${NC}"
        return 1
    fi

    echo -e "${GREEN}Starting LocalAI server...${NC}"
    echo "Container: $SIF"
    echo "--models-config-file=$SCRIPT_DIR/localai-models.yaml"
    echo "Port: $PORT"

    cd "$SCRIPT_DIR"

    # Check if container exists
    if [ \! -f "$SIF" ]; then
        echo -e "${RED}Error: Singularity image not found: $SIF${NC}"
        echo "Please build the image first with:"
        echo "  singularity build --remote localai.sif localai.def"
        return 1
    fi

    # Start CUDA MPS to allow multiple models per GPU
    # https://amirsojoodi.github.io/posts/Enabling-MPS/
    echo "Starting CUDA MPS daemon"
    nvidia-cuda-mps-control -d

    # Start LocalAI in standalone mode (no P2P, port 8081)
    # Mount SSL certificates for gallery access
    nohup singularity exec --nv \
        --env CUDA_VISIBLE_DEVICES=2,3 \
        -B "/data/models:/models" \
        -B /etc/ssl/certs:/etc/ssl/certs:ro \
        -B /etc/pki:/etc/pki:ro \
        "$SIF" \
        /local-ai run \
        --models-path=/models \
        --models-config-file="$SCRIPT_DIR/localai-models.yaml" \
        --address="0.0.0.0:8081" \
        > "$LOGFILE" 2>&1 &

    echo $! > "$PIDFILE"

    # Wait for server to be ready
    echo "Waiting for server to start..."
    for i in {1..30}; do
        if grep -q "LocalAI is started and running" "$LOGFILE" 2>/dev/null; then
            echo -e "${GREEN}LocalAI server started successfully!${NC}"
            echo "Logs: $LOGFILE"
            return 0
        fi
        sleep 2
    done

    echo -e "${YELLOW}Server started but may not be fully ready. Check logs at $LOGFILE${NC}"
    return 0
}

stop_server() {
    if [ ! check_server ]; then
        echo -e "${YELLOW}LocalAI server is not running${NC}"
        return 1
    fi

    PID=$(cat "$PIDFILE")
    echo -e "${GREEN}Stopping LocalAI server (PID: $PID)...${NC}"
    kill $PID
    rm -f "$PIDFILE"

    # Wait for process to end
    for i in {1..10}; do
        if \! ps -p $PID > /dev/null 2>&1; then
            echo -e "${GREEN}LocalAI server stopped${NC}"
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
        echo -e "${GREEN}LocalAI server is running (PID: $PID)${NC}"

        # Show GPU usage
        echo ""
        echo "GPU Usage:"
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader

        # Show recent logs
        echo ""
        echo "Recent logs:"
        tail -5 "$LOGFILE" 2>/dev/null || echo "No log file found"

        return 0
    else
        echo -e "${RED}LocalAI server is not running${NC}"
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
