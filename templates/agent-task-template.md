# Agent Task Template

## Goal
- 무엇을 계약 기준으로 맞추는지 1~2줄로 명시

## Contract Source
- Repo: `https://github.com/jho951/service-contract`
- Commit SHA: `<contract-sha>`
- Referenced Docs:
  - `shared/routing.md`
  - `shared/headers.md`
  - `shared/security.md`
  - `repositories/auth-service/README.md`
  - `repositories/auth-service/api.md`
  - `repositories/auth-service/v2.md`
  - `repositories/auth-service/security.md`
  - `repositories/auth-service/ops.md`
  - `repositories/auth-service/errors.md`
  - `artifacts/openapi/auth-service.v2.yaml`
  - `repositories/authz-service/README.md`
  - `repositories/authz-service/api.md`
  - `repositories/authz-service/v2.md`
  - `repositories/authz-service/policy-model.md`
  - `repositories/authz-service/policy-engine.md`
  - `repositories/authz-service/delegation.md`
  - `repositories/authz-service/versioning.md`
  - `repositories/authz-service/introspection.md`
  - `repositories/authz-service/cache.md`
  - `repositories/authz-service/external-boundaries.md`
  - `repositories/authz-service/rbac.md`
  - `repositories/authz-service/audit.md`
  - `repositories/authz-service/security.md`
  - `repositories/authz-service/ops.md`
  - `repositories/authz-service/errors.md`
  - `artifacts/openapi/authz-service.v2.yaml`
  - `repositories/redis-service/README.md`
  - `repositories/redis-service/keys.md`
  - `repositories/redis-service/security.md`
  - `repositories/redis-service/ops.md`
  - `repositories/monitoring-service/README.md`
  - `repositories/monitoring-service/targets.md`
  - `repositories/monitoring-service/security.md`
  - `repositories/monitoring-service/ops.md`
  - `shared/audit.md`
  - `registry/service-ownership.md`
  - `registry/adoption-matrix.md`
  - `repositories/user-service/README.md`
  - `repositories/user-service/api.md`
  - `repositories/user-service/security.md`
  - `repositories/user-service/ops.md`
  - `repositories/user-service/errors.md`
  - `repositories/user-service/visibility.md`
  - `repositories/gateway-service/errors.md`
  - `shared/env.md`
  - `artifacts/openapi/<service>.v1.yaml`

## Impacted Services
- `gateway-service (main)`:
- `auth-service (main)`:
- `authz-service (main)`:
- `user-service (main)`:
- `redis-service (main)`:
- `editor-service (dev)`:
- `monitoring-service (main)`:
- `Editor-page (master)`:
- `Explain-page (main)`:

## Change Plan
1. contract 문서/OpenAPI 갱신
2. 서비스 구현 반영
3. `contract.lock.yml` 업데이트
4. CI 계약 검증/스모크 확인

## Validation
- 실행 명령:
  - `<test-or-smoke-command-1>`
  - `<test-or-smoke-command-2>`
- 결과 요약:
  - `<pass/fail + 핵심 로그>`

## PR Body Snippet
```md
Contract SHA: <contract-sha>
Contract Lock: contract.lock.yml
Contract Areas: routing, headers, security, auth, auth-v2, authz, authz-v2, authz-rbac, authz-audit, authz-policy, authz-policy-engine, authz-delegation, authz-versioning, authz-introspection, authz-cache, authz-boundaries, user, user-visibility, redis, redis-keys, redis-security, redis-ops, monitoring, monitoring-targets, monitoring-security, monitoring-ops, audit, auth-ops, auth-errors, authz-ops, authz-errors, user-ops, user-errors, env, openapi
Validation: <commands/results>
```
