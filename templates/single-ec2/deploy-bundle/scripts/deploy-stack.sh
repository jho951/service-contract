#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_ENV="${BACKEND_ENV:-$ROOT_DIR/.env.backend}"
FRONTEND_ENV="${FRONTEND_ENV:-$ROOT_DIR/.env.frontend}"
BACKEND_COMPOSE="$ROOT_DIR/docker-compose.backend.yml"
FRONTEND_COMPOSE="$ROOT_DIR/docker-compose.frontend.yml"
NETWORK_NAME="${SERVICE_SHARED_NETWORK:-service-backbone-shared}"
ACTION="${1:-up}"
shift || true
TARGET_SERVICES=("$@")

BACKEND_SERVICES=(
  redis-server
  redis-exporter
  auth-mysql
  auth-service
  user-mysql
  user-service
  authz-service
  editor-mysql
  editor-service
  gateway-service
  prometheus
  grafana
  loki
  promtail
)

FRONTEND_SERVICES=(
  editor-page
  explain-page
)

BACKEND_TARGETS=()
FRONTEND_TARGETS=()

usage() {
  echo "Usage: deploy-stack.sh [up|down|restart|pull|ps|logs] [service-name ...]" >&2
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

in_list() {
  local target="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

classify_targets() {
  local service
  for service in "${TARGET_SERVICES[@]}"; do
    if in_list "$service" "${BACKEND_SERVICES[@]}"; then
      BACKEND_TARGETS+=("$service")
    elif in_list "$service" "${FRONTEND_SERVICES[@]}"; then
      FRONTEND_TARGETS+=("$service")
    else
      echo "Unsupported service: $service" >&2
      usage
    fi
  done
}

has_target_filter() {
  [[ ${#TARGET_SERVICES[@]} -gt 0 ]]
}

backend_selected() {
  [[ ${#TARGET_SERVICES[@]} -eq 0 || ${#BACKEND_TARGETS[@]} -gt 0 ]]
}

frontend_selected() {
  [[ ${#TARGET_SERVICES[@]} -eq 0 || ${#FRONTEND_TARGETS[@]} -gt 0 ]]
}

backend_run() {
  local subcommand="$1"
  shift
  if has_target_filter; then
    backend "$subcommand" "$@" "${BACKEND_TARGETS[@]}"
  else
    backend "$subcommand" "$@"
  fi
}

frontend_run() {
  local subcommand="$1"
  shift
  if has_target_filter; then
    frontend "$subcommand" "$@" "${FRONTEND_TARGETS[@]}"
  else
    frontend "$subcommand" "$@"
  fi
}

backend_up_with_retry() {
  if backend_run up -d; then
    return 0
  fi

  echo "Backend deploy failed once; waiting for dependency recovery and retrying..." >&2
  sleep 15
  backend_run up -d
}

frontend_up_with_retry() {
  if frontend_run up -d; then
    return 0
  fi

  echo "Frontend deploy failed once; waiting for dependency recovery and retrying..." >&2
  sleep 15
  frontend_run up -d
}

pull_with_retry() {
  local target="$1"
  if [[ "$target" == "backend" ]]; then
    if backend_run pull; then
      return 0
    fi
    echo "Backend pull failed once; retrying..." >&2
    sleep 15
    backend_run pull
    return 0
  fi

  if frontend_run pull; then
    return 0
  fi
  echo "Frontend pull failed once; retrying..." >&2
  sleep 15
  frontend_run pull
}

selected_down() {
  if backend_selected && [[ ${#BACKEND_TARGETS[@]} -gt 0 ]]; then
    backend stop "${BACKEND_TARGETS[@]}"
    backend rm -f "${BACKEND_TARGETS[@]}"
  fi

  if frontend_selected && [[ ${#FRONTEND_TARGETS[@]} -gt 0 ]]; then
    frontend stop "${FRONTEND_TARGETS[@]}"
    frontend rm -f "${FRONTEND_TARGETS[@]}"
  fi
}

classify_targets
if backend_selected; then
  ensure_file "$BACKEND_ENV"
fi
if frontend_selected; then
  ensure_file "$FRONTEND_ENV"
fi
ensure_network

case "$ACTION" in
  up)
    if backend_selected; then
      pull_with_retry backend
      backend_up_with_retry
    fi
    if frontend_selected; then
      pull_with_retry frontend
      frontend_up_with_retry
    fi
    ;;
  down)
    if has_target_filter; then
      selected_down
    else
      frontend down --remove-orphans
      backend down --remove-orphans
    fi
    ;;
  restart)
    if backend_selected; then
      pull_with_retry backend
      backend_up_with_retry
    fi
    if frontend_selected; then
      pull_with_retry frontend
      frontend_up_with_retry
    fi
    ;;
  pull)
    if backend_selected; then
      pull_with_retry backend
    fi
    if frontend_selected; then
      pull_with_retry frontend
    fi
    ;;
  ps)
    if backend_selected; then
      backend_run ps
    fi
    if frontend_selected; then
      frontend_run ps
    fi
    ;;
  logs)
    if [[ ${#BACKEND_TARGETS[@]} -gt 0 && ${#FRONTEND_TARGETS[@]} -gt 0 ]]; then
      echo "logs with mixed backend/frontend targets is not supported; run separate commands." >&2
      exit 1
    fi
    if [[ ${#FRONTEND_TARGETS[@]} -gt 0 ]]; then
      frontend_run logs -f
    else
      backend_run logs -f
    fi
    ;;
  *)
    usage
    ;;
esac
