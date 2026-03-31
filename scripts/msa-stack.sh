#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MSA_HOME="${MSA_HOME:-$HOME/msa}"
SHARED_NETWORK="${SHARED_SERVICE_NETWORK:-service-backbone-shared}"
ACTION="${1:-up}"

GATEWAY_REPO_URL="${GATEWAY_REPO_URL:-https://github.com/jho951/Api-gateway-server.git}"
AUTH_REPO_URL="${AUTH_REPO_URL:-https://github.com/jho951/Auth-server.git}"
PERMISSION_REPO_URL="${PERMISSION_REPO_URL:-https://github.com/jho951/Permission-server.git}"
USER_REPO_URL="${USER_REPO_URL:-https://github.com/jho951/User-server.git}"
REDIS_REPO_URL="${REDIS_REPO_URL:-https://github.com/jho951/Redis-server.git}"
BLOCK_REPO_URL="${BLOCK_REPO_URL:-https://github.com/jho951/Block-server.git}"

REPOS=(
  "Api-gateway-server|$GATEWAY_REPO_URL|main"
  "Auth-server|$AUTH_REPO_URL|main"
  "Permission-server|$PERMISSION_REPO_URL|main"
  "User-server|$USER_REPO_URL|main"
  "Redis-server|$REDIS_REPO_URL|main"
  "Block-server|$BLOCK_REPO_URL|dev"
)

ensure_repo() {
  local name="$1" url="$2" branch="$3"
  local dir="$MSA_HOME/$name"
  if [[ ! -d "$dir/.git" ]]; then
    git clone "$url" "$dir"
  fi

  git -C "$dir" fetch --all --prune
  git -C "$dir" checkout "$branch"
  git -C "$dir" pull --ff-only origin "$branch"
}

prepare_repos() {
  mkdir -p "$MSA_HOME"
  for item in "${REPOS[@]}"; do
    IFS='|' read -r name url branch <<< "$item"
    ensure_repo "$name" "$url" "$branch"
  done
}

ensure_network() {
  docker network inspect "$SHARED_NETWORK" >/dev/null 2>&1 || docker network create "$SHARED_NETWORK" >/dev/null
}

connect_alias() {
  local container="$1" alias="$2"
  if ! docker ps --format '{{.Names}}' | grep -qx "$container"; then
    return 0
  fi

  if docker network inspect "$SHARED_NETWORK" --format '{{json .Containers}}' | grep -q "\"Name\":\"$container\""; then
    return 0
  fi

  docker network connect --alias "$alias" "$SHARED_NETWORK" "$container" >/dev/null 2>&1 || true
}

wait_for_permission_service() {
  for _ in $(seq 1 60); do
    if curl -fsS http://127.0.0.1:8084/health >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "[WARN] Permission-server did not become ready in time." >&2
  return 1
}

up_stack() {
  prepare_repos
  ensure_network

  (
    cd "$MSA_HOME/Redis-server"
    SHARED_SERVICE_NETWORK="$SHARED_NETWORK" ./scripts/run.docker.sh up
  )

  (
    cd "$MSA_HOME/Auth-server"
    if [[ ! -f ".env.dev" ]]; then
      echo "[WARN] Auth-server/.env.dev not found. Create it before full integration." >&2
    fi
    ./scripts/run.docker.sh up dev app || true
  )

  (
    cd "$MSA_HOME/Permission-server"
    if docker ps --format '{{.Names}}' | grep -qx "permission-service"; then
      echo "[INFO] Permission-server container already running." >&2
    else
      docker rm -f permission-service >/dev/null 2>&1 || true
      docker run -d \
        --name permission-service \
        --network "$SHARED_NETWORK" \
        -p 8084:8084 \
        -v "$MSA_HOME/Permission-server:/workspace" \
        -w /workspace \
        eclipse-temurin:17-jdk \
        sh -lc './gradlew bootRun' >/dev/null
    fi
  )

  wait_for_permission_service || true

  (
    cd "$MSA_HOME/User-server"
    SHARED_SERVICE_NETWORK="$SHARED_NETWORK" ./scripts/run.docker.sh dev
  )

  (
    cd "$MSA_HOME/Block-server"
    ./scripts/run-docker.sh dev up
  )

  (
    cd "$MSA_HOME/Api-gateway-server"
    SHARED_SERVICE_NETWORK="$SHARED_NETWORK" ./scripts/run.docker.sh local -d
  )

  # Bridge services that do not join shared network by default.
  connect_alias "auth-service" "auth-service"
  connect_alias "permission-service" "permission-service"
  connect_alias "permission-server" "permission-service"
  connect_alias "user-server-dev" "user-service"
  connect_alias "documents-app-dev" "documents-service"
  connect_alias "central-redis" "redis-server"

  echo "[OK] MSA stack is up on network: $SHARED_NETWORK"
}

down_stack() {
  (
    cd "$MSA_HOME/Api-gateway-server" 2>/dev/null && SHARED_SERVICE_NETWORK="$SHARED_NETWORK" ./scripts/run.docker.sh local down || true
  )
  (
    cd "$MSA_HOME/Block-server" 2>/dev/null && ./scripts/run-docker.sh dev down || true
  )
  (
    cd "$MSA_HOME/User-server" 2>/dev/null && docker compose -f docker/docker-compose.dev.yml down || true
  )
  (
    cd "$MSA_HOME/Auth-server" 2>/dev/null && ./scripts/run.docker.sh down dev app || true
  )
  (
    cd "$MSA_HOME/Permission-server" 2>/dev/null && {
      docker rm -f permission-service >/dev/null 2>&1 || true
    }
  )
  (
    cd "$MSA_HOME/Redis-server" 2>/dev/null && ./scripts/run.docker.sh down || true
  )
  echo "[OK] MSA stack down"
}

ps_stack() {
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | rg -n "gateway|auth|permission|user|documents|redis" -N || true
}

case "$ACTION" in
  init)
    prepare_repos
    ensure_network
    echo "[OK] repositories synced and network ready"
    ;;
  up)
    up_stack
    ;;
  down)
    down_stack
    ;;
  ps)
    ps_stack
    ;;
  *)
    echo "Usage: $0 [init|up|down|ps]" >&2
    exit 1
    ;;
esac
