#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: deploy-single-ec2-service.sh <service-name> <repo-dir> [up|down|restart|logs|ps|pull]" >&2
  exit 1
}

SERVICE_NAME="${1:-}"
REPO_DIR="${2:-}"
ACTION="${3:-up}"
TEMP_ENV_FILE=""

[[ -n "$SERVICE_NAME" && -n "$REPO_DIR" ]] || usage
[[ -d "$REPO_DIR" ]] || { echo "Repo dir not found: $REPO_DIR" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OVERRIDE_DIR="$TEMPLATE_ROOT/overrides"
NETWORK_NAME="${SERVICE_SHARED_NETWORK:-service-backbone-shared}"

cleanup() {
  if [[ -n "$TEMP_ENV_FILE" && -f "$TEMP_ENV_FILE" ]]; then
    rm -f "$TEMP_ENV_FILE"
  fi
}
trap cleanup EXIT

declare -A SERVICE_PROJECT_NAME=(
  [gateway-service]="gateway-service"
  [auth-service]="auth-service"
  [user-service]="user-service-prod"
  [authz-service]="authz-service"
  [editor-service]="editor-service-prod"
  [redis-service]="redis-server"
  [monitoring-service]="monitoring-server"
)

declare -A SERVICE_DEFAULT_ENV_FILE=(
  [gateway-service]=".env.prod"
  [auth-service]=".env.prod"
  [user-service]=".env.prod"
  [authz-service]=".env.prod"
  [editor-service]=".env.prod"
  [redis-service]="env.docker.prod"
  [monitoring-service]=".env.prod"
)

declare -A SERVICE_ENV_MODE=(
  [gateway-service]="required"
  [auth-service]="required"
  [user-service]="required"
  [authz-service]="required"
  [editor-service]="required"
  [redis-service]="required"
  [monitoring-service]="optional"
)

declare -A SERVICE_ALLOW_ENV_OVERRIDE=(
  [redis-service]="true"
  [monitoring-service]="true"
)

declare -A SERVICE_COMPOSE_FILES=(
  [gateway-service]="docker/compose.yml docker/prod/compose.yml"
  [auth-service]="docker/compose.yml docker/prod/compose.yml"
  [user-service]="docker/compose.yml docker/prod/compose.yml"
  [authz-service]="docker/compose.yml docker/prod/compose.yml"
  [editor-service]="docker/prod/compose.yml"
  [redis-service]="docker/prod/compose.yml"
  [monitoring-service]="docker/prod/compose.yml"
)

declare -A SERVICE_OVERRIDE_FILE=(
  [gateway-service]="gateway-service.single-ec2.override.yml"
  [auth-service]="auth-service.single-ec2.override.yml"
  [user-service]="user-service.single-ec2.override.yml"
  [authz-service]="authz-service.single-ec2.override.yml"
  [editor-service]="editor-service.single-ec2.override.yml"
  [redis-service]="redis-service.single-ec2.override.yml"
  [monitoring-service]="monitoring-service.single-ec2.override.yml"
)

TARGET_ENV_FILE=""
TARGET_PROJECT_NAME=""
TARGET_COMPOSE_ARGS=()

ensure_network() {
  if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "Creating external docker network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME" >/dev/null
  fi
}

compose_up() {
  local env_file="$1"
  shift
  SERVICE_SHARED_NETWORK="$NETWORK_NAME" BACKEND_SHARED_NETWORK="$NETWORK_NAME" MSA_SHARED_NETWORK="$NETWORK_NAME" SHARED_SERVICE_NETWORK="$NETWORK_NAME" \
    docker compose --env-file "$env_file" "$@"
}

run_compose() {
  local env_file="$1"
  local project_name="$2"
  shift 2
  case "$ACTION" in
    up) compose_up "$env_file" -p "$project_name" "$@" pull && compose_up "$env_file" -p "$project_name" "$@" up -d ;;
    down) compose_up "$env_file" -p "$project_name" "$@" down --remove-orphans ;;
    restart) compose_up "$env_file" -p "$project_name" "$@" pull && compose_up "$env_file" -p "$project_name" "$@" up -d ;;
    logs) compose_up "$env_file" -p "$project_name" "$@" logs -f ;;
    ps) compose_up "$env_file" -p "$project_name" "$@" ps ;;
    pull) compose_up "$env_file" -p "$project_name" "$@" pull ;;
    *) usage ;;
  esac
}

resolve_env_file() {
  local service="$1"
  local env_path=""

  if [[ "${SERVICE_ALLOW_ENV_OVERRIDE[$service]:-false}" == "true" && -n "${ENV_FILE:-}" ]]; then
    env_path="$ENV_FILE"
  else
    env_path="$REPO_DIR/${SERVICE_DEFAULT_ENV_FILE[$service]}"
  fi

  if [[ -f "$env_path" ]]; then
    printf '%s\n' "$env_path"
    return 0
  fi

  if [[ "${SERVICE_ENV_MODE[$service]}" == "optional" ]]; then
    TEMP_ENV_FILE="$(mktemp "/tmp/${service}.XXXXXX")"
    : > "$TEMP_ENV_FILE"
    printf '%s\n' "$TEMP_ENV_FILE"
    return 0
  fi

  echo "Env file not found: $env_path" >&2
  exit 1
}

prepare_service() {
  local file

  [[ -n "${SERVICE_PROJECT_NAME[$SERVICE_NAME]:-}" ]] || {
    echo "Unsupported service: $SERVICE_NAME" >&2
    exit 1
  }

  TARGET_ENV_FILE="$(resolve_env_file "$SERVICE_NAME")"
  TARGET_PROJECT_NAME="${SERVICE_PROJECT_NAME[$SERVICE_NAME]}"
  TARGET_COMPOSE_ARGS=()

  for file in ${SERVICE_COMPOSE_FILES[$SERVICE_NAME]}; do
    TARGET_COMPOSE_ARGS+=(-f "$REPO_DIR/$file")
  done
  TARGET_COMPOSE_ARGS+=(-f "$OVERRIDE_DIR/${SERVICE_OVERRIDE_FILE[$SERVICE_NAME]}")
}

ensure_network
prepare_service
run_compose "$TARGET_ENV_FILE" "$TARGET_PROJECT_NAME" "${TARGET_COMPOSE_ARGS[@]}"
