#!/bin/bash
# ================================================================
# DNS & Reverse Proxy Infrastructure Deployment Script
# ---------------------------------------------------------------
# Automates Docker Compose stack management for:
#   - BIND9 DNS
#   - Traefik Reverse Proxy (Cloudflare or Namecheap ACME)
#   - Nginx test backend
#   - Portainer
# Supports: up | down | restart | status
# Includes: Logging, container health status
# Default provider: Cloudflare
# Author: Anganba Singha
# ================================================================

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Root path
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Compose file paths
BIND_COMPOSE="${PROJECT_ROOT}/bind9/docker-compose.yaml"
TRAEFIK_COMPOSE="${PROJECT_ROOT}/Traefik/docker-compose.yaml"
PORTAINER_COMPOSE="${PROJECT_ROOT}/Portainer-Server/docker-compose.yaml"
NGINX_COMPOSE="${PROJECT_ROOT}/nginx/docker-compose.yaml"

# Detect Docker or Podman
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

# ----------------------------------------------------------------
# Provider configuration (Cloudflare by default)
# ----------------------------------------------------------------
PROVIDER=$(echo "${2:-cloudflare}" | tr '[:upper:]' '[:lower:]')  # normalize to lowercase

case "$PROVIDER" in
  cloudflare)
    ENV_FILE="${PROJECT_ROOT}/Traefik/.env.cloudflare"
    ;;
  namecheap)
    ENV_FILE="${PROJECT_ROOT}/Traefik/.env.namecheap"
    ;;
  *)
    echo -e "${RED}[✗] Unknown provider: $PROVIDER (use 'cloudflare' or 'namecheap')${NC}"
    exit 1
    ;;
esac

# Verify environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo -e "${RED}[✗] Environment file not found:${NC} $ENV_FILE"
  exit 1
fi

# Export provider to ensure Docker Compose variable expansion
export PROVIDER
export ENV_FILE

# Logging helpers with timestamp
timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
log()    { echo -e "${GREEN}[$(timestamp)] [+]${NC} $1"; }
warn()   { echo -e "${YELLOW}[$(timestamp)] [!]${NC} $1"; }
error()  { echo -e "${RED}[$(timestamp)] [✗]${NC} $1"; }
section(){ echo -e "\n${BLUE}=== $1 ===${NC}"; }

# ----------------------------------------------------------------
# Deploy functions
# ----------------------------------------------------------------
compose_up() {
  section "Starting DNS & Reverse Proxy Stack (${PROVIDER^^})"

  log "Starting BIND9 DNS Server..."
  $COMPOSE_CMD -f "$BIND_COMPOSE" up -d || { error "Failed to start BIND9"; exit 1; }

  log "Starting Traefik Reverse Proxy (${PROVIDER})..."
  $COMPOSE_CMD --env-file "$ENV_FILE" -f "$TRAEFIK_COMPOSE" up -d || {
    error "Failed to start Traefik ($PROVIDER)"
    exit 1
  }

  log "Starting Nginx Backend..."
  $COMPOSE_CMD -f "$NGINX_COMPOSE" up -d || { error "Failed to start Nginx"; exit 1; }

  log "Starting Portainer UI..."
  $COMPOSE_CMD -f "$PORTAINER_COMPOSE" up -d || { error "Failed to start Portainer"; exit 1; }

  section "All Services Started Successfully (${PROVIDER^^})"
  show_status
}

compose_down() {
  section "Stopping All Services (${PROVIDER^^})"
  $COMPOSE_CMD -f "$PORTAINER_COMPOSE" down
  $COMPOSE_CMD -f "$NGINX_COMPOSE" down
  $COMPOSE_CMD -f "$TRAEFIK_COMPOSE" down
  $COMPOSE_CMD -f "$BIND_COMPOSE" down
  log "All services have been stopped."
}

compose_restart() {
  section "Restarting All Services (${PROVIDER^^})"
  compose_down
  sleep 3
  compose_up
}

# ----------------------------------------------------------------
# Show service status and health checks
# ----------------------------------------------------------------
show_status() {
  section "Container Status Summary"

  containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

  if [[ -z "$containers" ]]; then
    warn "No running containers found."
    return
  fi

  echo -e "${YELLOW}Health Checks:${NC}"
  echo "$containers" | awk -v green="$GREEN" -v yellow="$YELLOW" -v red="$RED" -v nc="$NC" '
    NR==1 {print; next}
    /healthy/    {print green $0 nc; next}
    /starting/   {print yellow $0 nc; next}
    /unhealthy/  {print red $0 nc; next}
    {print $0}
  '
}

# ----------------------------------------------------------------
# Main control
# ----------------------------------------------------------------
case "$1" in
  up)
    compose_up
    ;;
  down)
    compose_down
    ;;
  restart)
    compose_restart
    ;;
  status)
    show_status
    ;;
  *)
    echo -e "${YELLOW}Usage:${NC} $0 {up|down|restart|status} [cloudflare|namecheap]"
    echo
    echo "Examples:"
    echo "  $0 up                 # Start stack using Cloudflare (default)"
    echo "  $0 up namecheap       # Start stack using Namecheap"
    echo "  $0 restart cloudflare # Restart stack using Cloudflare"
    echo "  $0 status             # Show running containers"
    exit 1
    ;;
esac
