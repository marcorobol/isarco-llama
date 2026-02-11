#!/bin/bash
# Management script for Netdata monitoring using Singularity

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../.env"

# Configuration
INSTANCE_NAME="netdata"
PORT=19999
PIDFILE="$SCRIPT_DIR/netdata.pid"
IMAGE="docker://netdata/netdata:stable"

# Writable state directories
STATE_DIR="$SCRIPT_DIR/state"
mkdir -p "$STATE_DIR"/{cache,lib,log,config,go.d.conf.d}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SINGULARITY_CMD="singularity"
mkdir -p "$SCRIPT_DIR/logs"

check_instance() {
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            if ps -p "$PID" -o command= | grep -q "$SINGULARITY_CMD"; then
                return 0
            fi
        fi
    fi
    return 1
}

start_instance() {
    if check_instance; then
        echo -e "${YELLOW}Netdata is already running (PID: $(cat $PIDFILE))${NC}"
        return 1
    fi

    echo -e "${GREEN}Starting Netdata instance...${NC}"
    echo "Dashboard: http://localhost:$PORT"

    # Build singularity command - run directly from docker:// URL
    local singularity_opts=(
        run
        --nv
        --pwd "/"
        --bind "/:/host/root:ro"
        --bind "/etc/passwd:/host/etc/passwd:ro"
        --bind "/etc/group:/host/etc/group:ro"
        --bind "/etc/os-release:/host/etc/os-release:ro"
        --bind "/proc:/host/proc:ro"
        --bind "/sys:/host/sys:ro"
        --bind "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro"
        --bind "/etc/ssl/certs:/etc/ssl/certs:ro"
        --bind "/etc/pki:/etc/pki:ro"
        # Writable state directories
        --bind "$STATE_DIR/cache:/var/cache/netdata"
        --bind "$STATE_DIR/lib:/var/lib/netdata"
        --bind "$STATE_DIR/log:/var/log/netdata"
        --bind "$STATE_DIR/config:/var/lib/netdata/config"
        # Collector configs (mount to go.d.conf.d as per netdata structure)
        --bind "$STATE_DIR/go.d.conf.d/nvidia_smi.conf:/etc/netdata/go.d.conf.d/nvidia_smi.conf:ro"
    )

    # Add environment variables
    if [ -n "$NETDATA_CLAIM_TOKEN" ]; then
        echo "Claim token found - connecting to Netdata Cloud..."
        singularity_opts+=("--env" "NETDATA_CLAIM_TOKEN=$NETDATA_CLAIM_TOKEN")
    else
        echo -e "${YELLOW}No claim token found - running in standalone mode${NC}"
    fi

    # Set hostname for netdata
    singularity_opts+=("--env" "HOSTNAME=$(hostname)")
    singularity_opts+=("--env" "NETDATA_CLOUD_ENABLED=false")

    # Start in background with logging
    # Note: --nv flag provides GPU access, nvidia_smi collector should auto-detect
    $SINGULARITY_CMD "${singularity_opts[@]}" "$IMAGE" \
        > "$SCRIPT_DIR/logs/netdata.log" 2>&1 &

    local PID=$!
    echo "$PID" > "$PIDFILE"

    # Wait for Netdata to be ready
    echo "Waiting for Netdata to start..."
    local max_wait=60
    local waited=0

    while [ $waited -lt $max_wait ]; do
        if kill -0 "$PID" 2>/dev/null; then
            if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
                echo -e "${GREEN}Netdata started successfully!${NC}"
                echo ""
                echo "Dashboard Access:"
                echo "  - Local:  http://localhost:$PORT"
                echo "  - Remote: http://$(hostname -f):$PORT"
                echo ""
                echo "Logs: $SCRIPT_DIR/logs/netdata.log"
                if [ -n "$NETDATA_CLAIM_TOKEN" ]; then
                    echo "Netdata Cloud: Check your cloud dashboard for connected room"
                fi
                return 0
            fi
        else
            echo ""
            echo -e "${RED}Netdata process died!${NC}"
            echo "Check logs at: $SCRIPT_DIR/logs/netdata.log"
            rm -f "$PIDFILE"
            return 1
        fi
        sleep 1
        waited=$((waited + 1))
        echo -n "."
    done

    echo ""
    echo -e "${YELLOW}Netdata is starting but health check not yet passed.${NC}"
    echo "Check logs with: $0 logs"
    return 0
}

stop_instance() {
    if ! check_instance; then
        echo -e "${YELLOW}Netdata is not running${NC}"
        rm -f "$PIDFILE"
        return 1
    fi

    PID=$(cat "$PIDFILE")
    echo -e "${GREEN}Stopping Netdata (PID: $PID)...${NC}"

    kill "$PID" 2>/dev/null || true

    local waited=0
    while [ $waited -lt 10 ]; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            break
        fi
        sleep 1
        waited=$((waited + 1))
    done

    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Force killing Netdata..."
        kill -9 "$PID" 2>/dev/null || true
    fi

    rm -f "$PIDFILE"
    echo -e "${GREEN}Netdata stopped${NC}"
    return 0
}

status_instance() {
    if check_instance; then
        PID=$(cat "$PIDFILE")
        echo -e "${GREEN}Netdata is running (PID: $PID)${NC}"
        echo ""
        ps -p "$PID" -o pid,ppid,cmd,etime,stat
        echo ""
        if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
            echo -e "${GREEN}Dashboard: Ready${NC}"
        else
            echo -e "${YELLOW}Dashboard: Still starting...${NC}"
        fi
        if command -v nvidia-smi &> /dev/null; then
            echo ""
            echo "GPU Status:"
            nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader 2>/dev/null || echo "GPU info not available"
        fi
        echo ""
        echo "Dashboard Access:"
        echo "  - Local:  http://localhost:$PORT"
        echo "  - Remote: http://$(hostname -f):$PORT"
        echo ""
        echo "Logs: $SCRIPT_DIR/logs/netdata.log"
        return 0
    else
        echo -e "${RED}Netdata is not running${NC}"
        echo ""
        echo "Start with: $0 start"
        return 1
    fi
}

logs_instance() {
    if check_instance; then
        echo -e "${GREEN}Showing Netdata logs (Ctrl+C to exit):${NC}"
        echo ""
        tail -f "$SCRIPT_DIR/logs/netdata.log"
    else
        if [ -f "$SCRIPT_DIR/logs/netdata.log" ]; then
            echo -e "${YELLOW}Netdata is not running, showing last logs:${NC}"
            echo ""
            tail -n 50 "$SCRIPT_DIR/logs/netdata.log"
        else
            echo -e "${YELLOW}No logs found${NC}"
        fi
    fi
}

shell_instance() {
    echo -e "${GREEN}Starting shell... (exit to quit)${NC}"
    $SINGULARITY_CMD shell \
        --pwd "/" \
        --bind "/:/host/root:ro" \
        --bind "/proc:/host/proc:ro" \
        --bind "/sys:/host/sys:ro" \
        "$IMAGE"
}

clean_state() {
    echo -e "${YELLOW}Cleaning state directories...${NC}"
    stop_instance 2>/dev/null || true
    rm -rf "$STATE_DIR" "$PIDFILE"
    mkdir -p "$STATE_DIR"/{cache,lib,log,config}
    echo -e "${GREEN}State cleaned.${NC}"
}

case "${1:-start}" in
    start)
        start_instance
        ;;
    stop)
        stop_instance
        ;;
    restart)
        stop_instance
        sleep 2
        start_instance
        ;;
    status)
        status_instance
        ;;
    logs)
        logs_instance
        ;;
    shell)
        shell_instance
        ;;
    clean)
        clean_state
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|shell|clean}"
        echo ""
        echo "Commands:"
        echo "  start   - Start Netdata instance (runs from docker:// URL)"
        echo "  stop    - Stop Netdata instance"
        echo "  restart - Restart Netdata instance"
        echo "  status  - Show instance status and dashboard URLs"
        echo "  logs    - Show Netdata logs (live tail)"
        echo "  shell   - Start an interactive shell in the container"
        echo "  clean   - Remove state directories"
        exit 1
        ;;
esac
