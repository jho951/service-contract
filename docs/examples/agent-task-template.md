# Agent Task Template

## Goal
- 무엇을 계약 기준으로 맞추는지 1~2줄로 명시

## Contract Source
- Repo: `https://github.com/jho951/contract`
- Commit SHA: `<contract-sha>`
- Referenced Docs:
  - `contracts/common/routing.md`
  - `contracts/common/headers.md`
  - `contracts/common/security.md`
  - `contracts/auth/README.md`
  - `contracts/auth/api.md`
  - `contracts/auth/v2.md`
  - `contracts/auth/security.md`
  - `contracts/auth/ops.md`
  - `contracts/auth/errors.md`
  - `contracts/openapi/auth-service.v2.yaml`
  - `contracts/authz/README.md`
  - `contracts/authz/api.md`
  - `contracts/authz/v2.md`
  - `contracts/authz/policy-model.md`
  - `contracts/authz/delegation.md`
  - `contracts/authz/versioning.md`
  - `contracts/authz/introspection.md`
  - `contracts/authz/cache.md`
  - `contracts/authz/external-boundaries.md`
  - `contracts/authz/rbac.md`
  - `contracts/authz/audit.md`
  - `contracts/authz/security.md`
  - `contracts/authz/ops.md`
  - `contracts/authz/errors.md`
  - `contracts/openapi/authz-service.v2.yaml`
  - `contracts/redis/README.md`
  - `contracts/redis/keys.md`
  - `contracts/redis/security.md`
  - `contracts/redis/ops.md`
  - `contracts/common/service-ownership.md`
  - `contracts/common/adoption-matrix.md`
  - `contracts/user/README.md`
  - `contracts/user/api.md`
  - `contracts/user/security.md`
  - `contracts/user/ops.md`
  - `contracts/user/errors.md`
  - `contracts/user/visibility.md`
  - `contracts/gateway/errors.md`
  - `contracts/common/env.md`
  - `contracts/openapi/<service>.v1.yaml`

## Impacted Services
- `Api-gateway-server (main)`:
- `Auth-server (main)`:
  - `Authz-server (main)`:
- `User-server (main)`:
- `Redis-server (main)`:
- `Block-server (dev)`:
- `Editor-page (main)`:
- `Explain-page (main)`:

## Change Plan
1. contract 문서/OpenAPI 갱신
2. 서비스 구현 반영
3. `CONTRACT_SYNC.md` 업데이트
4. 검증/증빙

## Validation
- 실행 명령:
  - `<test-or-smoke-command-1>`
  - `<test-or-smoke-command-2>`
- 결과 요약:
  - `<pass/fail + 핵심 로그>`

## PR Body Snippet
```md
Contract SHA: <contract-sha>
Contract Areas: routing, headers, security, auth, auth-v2, authz, authz-v2, authz-rbac, authz-audit, authz-policy, authz-delegation, authz-versioning, authz-introspection, authz-cache, authz-boundaries, user, user-visibility, redis, redis-keys, redis-security, redis-ops, auth-ops, auth-errors, authz-ops, authz-errors, user-ops, user-errors, env, openapi
Validation: <commands/results>
```
