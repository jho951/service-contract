#!/usr/bin/env bash
set -Eeuo pipefail

# Run inside a service repository. Detect contract-impacting changes and
# fail when CONTRACT_SYNC.md is not updated in the same PR/branch.
#
# Usage:
#   ./scripts/contract-impact-check.sh <service> [base_ref]
# Example:
#   ./scripts/contract-impact-check.sh auth origin/main

SERVICE="${1:-}"
BASE_REF="${2:-origin/main}"

if [[ -z "$SERVICE" ]]; then
  echo "Usage: $0 <gateway|auth|permission|user|redis|block> [base_ref]" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] This script must run inside a git repository." >&2
  exit 2
fi

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "[WARN] Base ref '$BASE_REF' not found. Falling back to HEAD~1." >&2
  BASE_REF="HEAD~1"
fi

CHANGED_FILES="$(git diff --name-only "$BASE_REF"...HEAD || true)"
if [[ -z "$CHANGED_FILES" ]]; then
  echo "[OK] No changed files."
  exit 0
fi

match_any() {
  local regex="$1"
  echo "$CHANGED_FILES" | grep -E "$regex" >/dev/null 2>&1
}

detect_areas() {
  local service="$1"
  local areas=()

  case "$service" in
    gateway)
      match_any 'src/.*/routing|src/.*/Route|stripPrefix|GatewayConfig' && areas+=("routing")
      match_any 'src/.*/security|src/.*/jwt|src/.*/auth' && areas+=("security")
      match_any 'src/.*/header|trusted|X-Request-Id|X-Correlation-Id' && areas+=("headers")
      match_any 'src/.*/error|timeout|upstream|retry' && areas+=("errors")
      match_any '\.env|docker|compose|run\.docker\.sh' && areas+=("env")
      ;;
    auth)
      match_any 'src/.*/controller|oauth2|sso|/auth/|/oauth2/' && areas+=("routing")
      match_any 'src/.*/security|jwt|token|issuer|audience' && areas+=("security")
      match_any 'src/.*/header|X-User-Id|X-Request-Id|X-Correlation-Id' && areas+=("headers")
      match_any 'exception|error|timeout|fallback' && areas+=("errors")
      match_any '\.env|application-.*\.yml|docker|compose|run\.docker\.sh' && areas+=("env")
      ;;
    permission)
      match_any 'src/.*/controller|/permission/|/permissions/|/roles/|/policies/' && areas+=("routing")
      match_any 'src/.*/security|jwt|token|issuer|audience|role|permission|policy|authority|authz' && areas+=("security")
      match_any 'src/.*/header|X-User-Id|X-Request-Id|X-Correlation-Id' && areas+=("headers")
      match_any 'exception|error|timeout|fallback' && areas+=("errors")
      match_any '\.env|application-.*\.yml|docker|compose|run\.docker\.sh' && areas+=("env")
      ;;
    user)
      match_any 'src/.*/controller|/users/|/internal/users/' && areas+=("routing")
      match_any 'src/.*/security|jwt|internal.*secret|issuer|audience' && areas+=("security")
      match_any 'src/.*/header|X-User-Id|X-Request-Id|X-Correlation-Id' && areas+=("headers")
      match_any 'exception|error|timeout|fallback' && areas+=("errors")
      match_any '\.env|application-.*\.yml|docker|compose|run\.docker\.sh' && areas+=("env")
      ;;
    redis)
      match_any 'redis|session|cache|ttl|keyspace' && areas+=("routing")
      match_any 'auth|acl|password|secret|tls|ssl' && areas+=("security")
      match_any 'header|trace|request-id|correlation-id' && areas+=("headers")
      match_any 'error|timeout|retry' && areas+=("errors")
      match_any '\.env|docker|compose|run\.docker\.sh' && areas+=("env")
      ;;
    block)
      match_any 'documents|blocks|controller|/documents|/admin/blocks' && areas+=("routing")
      match_any 'security|jwt|auth|permission|role' && areas+=("security")
      match_any 'header|request-id|correlation-id' && areas+=("headers")
      match_any 'error|timeout|retry' && areas+=("errors")
      match_any '\.env|application-.*\.yml|docker|compose|run-docker\.sh|run\.docker\.sh' && areas+=("env")
      ;;
    *)
      echo "[ERROR] Unknown service '$service'." >&2
      echo "Use one of: gateway|auth|permission|user|redis|block" >&2
      exit 2
      ;;
  esac

  # Deduplicate in insertion order.
  local out=()
  local seen=" "
  local area
  for area in "${areas[@]}"; do
    if [[ "$seen" != *" $area "* ]]; then
      out+=("$area")
      seen="$seen$area "
    fi
  done
  printf '%s\n' "${out[@]}"
}

IMPACT_AREAS="$(detect_areas "$SERVICE" || true)"
if [[ -z "$IMPACT_AREAS" ]]; then
  echo "[OK] No contract-impacting changes detected for service: $SERVICE"
  exit 0
fi

if ! echo "$CHANGED_FILES" | grep -qx 'CONTRACT_SYNC.md'; then
  echo "[FAIL] Contract-impacting changes detected, but CONTRACT_SYNC.md was not updated."
  echo ""
  echo "Detected areas:"
  echo "$IMPACT_AREAS" | sed 's/^/- /'
  echo ""
  echo "Required actions:"
  echo "1. Update https://github.com/jho951/contract documents/OpenAPI for impacted areas."
  echo "2. Update this repository's CONTRACT_SYNC.md with the new contract SHA."
  exit 1
fi

echo "[OK] Contract-impacting changes detected and CONTRACT_SYNC.md was updated."
echo "Detected areas:"
echo "$IMPACT_AREAS" | sed 's/^/- /'
