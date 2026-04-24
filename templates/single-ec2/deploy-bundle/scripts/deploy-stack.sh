#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_ENV="${BACKEND_ENV:-$ROOT_DIR/.env.backend}"
FRONTEND_ENV="${FRONTEND_ENV:-$ROOT_DIR/.env.frontend}"
BACKEND_COMPOSE="$ROOT_DIR/docker-compose.backend.yml"
FRONTEND_COMPOSE="$ROOT_DIR/docker-compose.frontend.yml"
NETWORK_NAME="${SERVICE_SHARED_NETWORK:-service-backbone-shared}"
ACTION="${1:-up}"

usage() {
  echo "Usage: deploy-stack.sh [up|down|restart|pull|ps|logs]" >&2
  exit 1
}

ensure_file() {
  local path="$1"
  [[ -f "$path" ]] || { echo "Required file not found: $path" >&2; exit 1; }
}

ensure_network() {
  if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    docker network create "$NETWORK_NAME" >/dev/null
  fi
}

backend() {
  docker compose --env-file "$BACKEND_ENV" -f "$BACKEND_COMPOSE" "$@"
}

frontend() {
  docker compose --env-file "$FRONTEND_ENV" -f "$FRONTEND_COMPOSE" "$@"
}

backend_up_with_retry() {
  if backend up -d; then
    return 0
  fi

  echo "Backend deploy failed once; waiting for dependency recovery and retrying..." >&2
  sleep 15
  backend up -d
}

ensure_file "$BACKEND_ENV"
ensure_file "$FRONTEND_ENV"
ensure_network

case "$ACTION" in
  up)
    backend pull
    backend_up_with_retry
    frontend pull
    frontend up -d
    ;;
  down)
    frontend down --remove-orphans
    backend down --remove-orphans
    ;;
  restart)
    backend pull
    backend_up_with_retry
    frontend pull
    frontend up -d
    ;;
  pull)
    backend pull
    frontend pull
    ;;
  ps)
    backend ps
    frontend ps
    ;;
  logs)
    backend logs -f
    ;;
  *)
    usage
    ;;
esac
