#!/bin/bash
# Startup script for Ollama server
# Usage: ./run.sh [start|stop|restart|status|logs|run]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIF="$SCRIPT_DIR/ollama.sif"
DATA_DIR="/data/models/.ollama"
HOST="0.0.0.0"
PORT=11434
PIDFILE="$SCRIPT_DIR/ollama-server.pid"
LOGFILE="$SCRIPT_DIR/ollama-server.log"

# Default model for run command
MODEL="${MODEL:-llama2}"

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

    # Create data directory if it doesn't exist
    mkdir -p "$DATA_DIR"

    echo -e "${GREEN}Starting Ollama server...${NC}"
    echo "Data directory: $DATA_DIR"
    echo "Port: $PORT"

    cd "$SCRIPT_DIR"

    # Check if SIF file exists
    if [ ! -f "$SIF" ]; then
        echo -e "${YELLOW}Image not found. Pulling ollama.sif...${NC}"
        singularity pull "$SIF" docker://ollama/ollama
    fi

    nohup singularity exec --nv \
        -B "$DATA_DIR:/root/.ollama" \
        -B /etc/ssl/certs:/etc/ssl/certs:ro \
        -B /etc/pki:/etc/pki:ro \
        --env CUDA_VISIBLE_DEVICES=2,3 \
        --env OLLAMA_MODELS=/root/.ollama/models \
        --env OLLAMA_NUM_GPU=2 \
        --env OLLAMA_SCHED_SPREAD=true \
        "$SIF" \
        ollama serve \
        > "$LOGFILE" 2>&1 &

    echo $! > "$PIDFILE"

    # Wait for server to be ready
    echo "Waiting for server to start..."
    for i in {1..30}; do
        if curl -s "http://localhost:$PORT/api/tags" > /dev/null 2>&1; then
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
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "GPU info not available"

        # Show health
        if curl -s "http://localhost:$PORT/api/tags" > /dev/null 2>&1; then
            echo -e "${GREEN}Health: OK${NC}"

            # List installed models
            echo ""
            echo "Installed models:"
            curl -s "http://localhost:$PORT/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || echo "No models installed"
        else
            echo -e "${RED}Health: FAILED${NC}"
        fi

        echo ""
        echo "API Endpoints:"
        echo "  - Tags (models): http://localhost:$PORT/api/tags"
        echo "  - Generate:      http://localhost:$PORT/api/generate"
        echo "  - Chat:          http://localhost:$PORT/api/chat"

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

run_model() {
    local model="${1:-$MODEL}"

    # Check if server is running
    if ! check_server; then
        echo -e "${YELLOW}Server is not running. Starting it...${NC}"
        start_server
        sleep 3
    fi

    echo -e "${GREEN}Running model: $model${NC}"

    singularity exec --nv \
        -B "$DATA_DIR:/root/.ollama" \
        --env CUDA_VISIBLE_DEVICES=2,3 \
        --env OLLAMA_MODELS=/root/.ollama/models \
        "$SIF" \
        ollama run "$model"
}

pull_model() {
    local model="${1:-$MODEL}"

    echo -e "${GREEN}Pulling model: $model${NC}"

    singularity exec --nv \
        -B "$DATA_DIR:/root/.ollama" \
        --env CUDA_VISIBLE_DEVICES=2,3 \
        --env OLLAMA_MODELS=/root/.ollama/models \
        "$SIF" \
        ollama pull "$model"
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
    run)
        run_model "$2"
        ;;
    pull)
        pull_model "$2"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|run|pull}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the Ollama server"
        echo "  stop     - Stop the Ollama server"
        echo "  restart  - Restart the Ollama server"
        echo "  status   - Show server status and installed models"
        echo "  logs     - Show server logs"
        echo "  run      - Run a model (e.g., ./run.sh run llama2)"
        echo "  pull     - Pull a model (e.g., ./run.sh pull llama2)"
        exit 1
        ;;
esac
