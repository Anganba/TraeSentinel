#!/bin/bash
# ================================================================
# TraeSentinel Smart Stack Deployment Script
# ---------------------------------------------------------------
# Dynamically loads docker-compose files from stack.list
# Supports both Podman & Docker
# Provider: Cloudflare | Namecheap
# Author: Anganba Singha
# ================================================================

# Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[1;34m'; NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_LIST="${PROJECT_ROOT}/stack.list"

[[ ! -f "$STACK_LIST" ]] && { echo -e "${RED}[✗] Missing $STACK_LIST${NC}"; exit 1; }

# Compose detection
if command -v podman-compose &>/dev/null; then
  COMPOSE_CMD="podman-compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE_CMD="docker-compose"
elif command -v docker &>/dev/null; then
  COMPOSE_CMD="docker compose"
else
  echo -e "${RED}[✗] Neither Docker nor Podman found.${NC}"
  exit 1
fi

# Provider config
PROVIDER=$(echo "${2:-cloudflare}" | tr '[:upper:]' '[:lower:]')
case "$PROVIDER" in
  cloudflare) ENV_FILE="${PROJECT_ROOT}/Traefik/.env.cloudflare" ;;
  namecheap) ENV_FILE="${PROJECT_ROOT}/Traefik/.env.namecheap" ;;
  *) echo -e "${RED}[✗] Unknown provider: $PROVIDER${NC}"; exit 1 ;;
esac

[[ ! -f "$ENV_FILE" ]] && { echo -e "${RED}[✗] Missing env file:${NC} $ENV_FILE"; exit 1; }
export PROVIDER ENV_FILE

timestamp(){ date +"%Y-%m-%d %H:%M:%S"; }
log(){ echo -e "${GREEN}[$(timestamp)] [+]${NC} $1"; }
warn(){ echo -e "${YELLOW}[$(timestamp)] [!]${NC} $1"; }
error(){ echo -e "${RED}[$(timestamp)] [✗]${NC} $1"; }
section(){ echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Load compose paths into an array
mapfile -t COMPOSE_FILES < "$STACK_LIST"

compose_up(){
  section "Starting TraeSentinel Stack (${PROVIDER^^})"
  for path in "${COMPOSE_FILES[@]}"; do
    [[ -z "$path" ]] && continue  # skip empty lines
    [[ -d "$PROJECT_ROOT/$path" ]] && { warn "Skipping directory: $path"; continue; }

    SERVICE_NAME=$(basename "$(dirname "$path")")
    log "Starting ${SERVICE_NAME}..."
    # if [[ "$path" == *"Traefik/"* ]]; then
    #   $COMPOSE_CMD --env-file "$ENV_FILE" -f "${PROJECT_ROOT}/${path}" up -d || error "Failed: ${SERVICE_NAME}"
    # else
    #   $COMPOSE_CMD -f "${PROJECT_ROOT}/${path}" up -d || error "Failed: ${SERVICE_NAME}"
    # fi
    $COMPOSE_CMD --env-file "$ENV_FILE" -f "${PROJECT_ROOT}/${path}" up -d || error "Failed: ${SERVICE_NAME}"
  done

  section "All Services Started"
  show_status
}

compose_down(){
  section "Stopping All Services"
  # Stop in reverse order
  for ((i=${#COMPOSE_FILES[@]}-1; i>=0; i--)); do
    path="${COMPOSE_FILES[$i]}"
    SERVICE_NAME=$(basename "$(dirname "$path")")
    log "Stopping ${SERVICE_NAME}..."
    $COMPOSE_CMD -f "${PROJECT_ROOT}/${path}" down
  done
  log "All services stopped."
}

compose_restart(){
  section "Restarting Stack"
  compose_down
  sleep 3
  compose_up
}

show_status(){
  section "Container Status Summary"
  containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
  [[ -z "$containers" ]] && { warn "No running containers."; return; }
  echo -e "${YELLOW}Health Checks:${NC}"
  echo "$containers" | awk -v green="$GREEN" -v yellow="$YELLOW" -v red="$RED" -v nc="$NC" '
    NR==1 {print; next}
    /healthy/   {print green $0 nc; next}
    /starting/  {print yellow $0 nc; next}
    /unhealthy/ {print red $0 nc; next}
    {print $0}
  '
}

case "$1" in
  up) compose_up ;;
  down) compose_down ;;
  restart) compose_restart ;;
  status) show_status ;;
  *)
    echo -e "${YELLOW}Usage:${NC} $0 {up|down|restart|status} [cloudflare|namecheap]"
    echo "Example: $0 up cloudflare"
    exit 1
    ;;
esac

