#!/bin/bash
# Singularity run script for GLM-4 llama-server
# Usage: ./run-glm4-server.sh [start|stop|restart|status|logs]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIF="$SCRIPT_DIR/llamacpp-cuda-complete.sif"
MODEL="$SCRIPT_DIR/models/glm-4-9b-chat-Q5_K_M.gguf"
HOST="0.0.0.0"
PORT=8080
NGPUS=4
NGP_LAYERS=99
CTX_SIZE=4096
THREADS=8
PIDFILE="$SCRIPT_DIR/llama-server.pid"
LOGFILE="$SCRIPT_DIR/llama-server.log"

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
    
    echo -e "${GREEN}Starting GLM-4 llama-server...${NC}"
    echo "Model: $MODEL"
    echo "GPUs: $NGPUS"
    echo "Port: $PORT"
    
    cd "$SCRIPT_DIR"
    nohup singularity exec --nv -B "$SCRIPT_DIR/models:/models" "$SIF" \
        /opt/llama.cpp/build/bin/llama-server \
        -m "/models/$(basename "$MODEL")" \
        -ngl $NGP_LAYERS \
        -c $CTX_SIZE \
        --port $PORT \
        --host "$HOST" \
        -t $THREADS \
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
