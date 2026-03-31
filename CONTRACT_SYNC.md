# CONTRACT_SYNC.md

> 이 파일은 각 서비스 레포와 이 계약 레포에서 동일한 형식으로 유지한다.
> 계약 영향 변경이 있으면 이 파일을 먼저 갱신하고, 그 다음 구현 레포를 맞춘다.

## Repository
- Repo: `https://github.com/jho951/contract`
- Branch: `main`
- Role: `contract-source`

## Contract Source
- Contract Repo: `https://github.com/jho951/contract`
- Contract Commit SHA: `<contract-sha>`
- Latest Sync Date: `<YYYY-MM-DD>`

## Referenced Docs
- `README.md`
- `contracts/common/README.md`
- `contracts/common/service-ownership.md`
- `contracts/common/adoption-matrix.md`
- `contracts/common/change-process.md`
- `contracts/common/versioning.md`
- `contracts/common/routing.md`
- `contracts/common/headers.md`
- `contracts/common/security.md`
- `contracts/common/auth-channel-policy.md`
- `contracts/common/env.md`
- `contracts/auth/README.md`
- `contracts/auth/api.md`
- `contracts/auth/v2.md`
- `contracts/auth/security.md`
- `contracts/auth/ops.md`
- `contracts/auth/errors.md`
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
- `contracts/redis/README.md`
- `contracts/redis/keys.md`
- `contracts/redis/security.md`
- `contracts/redis/ops.md`
- `contracts/user/README.md`
- `contracts/user/api.md`
- `contracts/user/security.md`
- `contracts/user/ops.md`
- `contracts/user/errors.md`
- `contracts/user/v2-extension.md`
- `contracts/user/visibility.md`
- `contracts/editor/README.md`
- `contracts/editor/schema-v1.md`
- `contracts/editor/rules-v1.md`
- `contracts/editor/api.md`
- `contracts/editor/db-migration.md`
- `contracts/editor/authz.md`
- `contracts/editor/operations.md`
- `contracts/editor/errors.md`
- `contracts/editor/security.md`
- `contracts/editor/ops.md`
- `contracts/editor/cache.md`
- `contracts/editor/schema-v2.md`
- `contracts/editor/rules-v2.md`
- `contracts/editor/api-v2.md`
- `contracts/openapi/editor.v1.yaml`
- `contracts/openapi/editor.v2.yaml`
- `contracts/openapi/auth-service.v2.yaml`
- `contracts/gateway/README.md`
- `contracts/gateway/responsibility.md`
- `contracts/gateway/auth-proxy.md`
- `contracts/gateway/auth.md`
- `contracts/gateway/security.md`
- `contracts/gateway/cache.md`
- `contracts/gateway/response.md`
- `contracts/gateway/env.md`
- `contracts/gateway/errors.md`
- `contracts/gateway/execution.md`
- `contracts/openapi/gateway-edge.v1.yaml`
- `contracts/openapi/user-service.v1.yaml`
- `contracts/openapi/auth-service.v1.yaml`
- `contracts/openapi/authz-service.v1.yaml`
- `contracts/openapi/authz-service.v2.yaml`
- `contracts/openapi/block-service.v1.yaml`

## Impact Scope
- Contract Areas:
  - `common`
  - `routing`
  - `headers`
  - `security`
  - `editor`
  - `editor-v1`
  - `editor-v2`
  - `editor-migration`
  - `editor-authz`
  - `editor-operations`
  - `editor-errors`
  - `editor-security`
  - `editor-ops`
  - `editor-cache`
  - `auth`
  - `auth-v2`
  - `authz`
  - `authz-v2`
  - `authz-rbac`
  - `authz-audit`
  - `authz-policy`
  - `authz-delegation`
  - `authz-versioning`
  - `authz-introspection`
  - `authz-cache`
  - `authz-boundaries`
  - `cache`
  - `redis`
  - `redis-keys`
  - `redis-security`
  - `redis-ops`
  - `response`
  - `env`
  - `auth-service`
  - `authz-service`
  - `user-service`
  - `errors`
  - `auth-operations`
  - `auth-errors`
  - `user-operations`
  - `user-errors`
  - `user-v2-extension`
  - `user-visibility`
  - `openapi`
- Affected Flows:
  - `Gateway 인증 프록시`
  - `브라우저 인증`
  - `비브라우저 인증`
  - `Auth login/refresh/logout`
  - `Auth v2 MFA and step-up`
  - `Auth SSO and session validation`
  - `Auth internal account operations`
  - `Authz policy evaluation`
  - `Authz role and policy lookup`
  - `Authz authz versioning and policy evaluation`
  - `Authz audit logging`
  - `Authz policy model`
  - `Authz delegation`
  - `Authz introspection`
  - `Authz cache invalidation`
  - `Authz external boundaries`
  - `Redis key namespace and cache policy`
  - `Redis operational readiness`
  - `User signup and me`
  - `User internal create and social linking`
  - `User profile visibility and privacy`
  - `Auth operational validation`
  - `User operational validation`
  - `User v2 extension planning`
  - `내부 헤더 재주입`
  - `Gateway 응답 passthrough`
  - `health/ready`
  - `INTERNAL secret`
  - `L1/L2 session cache`
  - `Editor v1 Document/Block`
  - `Editor v2 Node migration`
  - `Editor authorization and ownership`
  - `Editor operations semantics`
  - `Editor error contract`
  - `Editor security`
  - `Editor operating contract`
  - `Editor cache contract`

## Validation
- Commands:
  - `git diff --check`
  - `./gradlew test`
  - `curl -i http://localhost:8080/v1/health`
  - `curl -i http://localhost:8080/v1/ready`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<routing, headers, ...>` | `<short note>` |
