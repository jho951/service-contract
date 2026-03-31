# CONTRACT_SYNC.md

## Repository
- Repo: `https://github.com/jho951/Authz-server`
- Branch: `main`
- Role: `backend-service`

## Contract Source
- Contract Repo: `https://github.com/jho951/contract`
- Contract Commit SHA: `<contract-sha>`
- Latest Sync Date: `<YYYY-MM-DD>`

## Referenced Contract Docs
- `contracts/common/routing.md`
- `contracts/common/headers.md`
- `contracts/common/security.md`
- `contracts/common/env.md`
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
- `contracts/common/service-ownership.md`
- `contracts/common/adoption-matrix.md`
- `contracts/gateway/errors.md`
- `contracts/openapi/authz-service.v1.yaml`
- `contracts/openapi/authz-service.v2.yaml`
- `contracts/openapi/*.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
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
  - `env`
  - `errors`
  - `openapi`
- Affected Endpoints or Flows:
  - `POST /permissions/internal/admin/verify`
  - `GET /health`
  - `GET /ready`
  - `POST /v2/permissions/authorize`
  - `GET /v2/permissions/users/{userId}`
  - `GET /v2/permissions/policies/{policyId}`
  - `POST /v2/permissions/internal/introspect`
  - `POST /v2/permissions/internal/changes/events`

## Service Notes
- Gateway의 `/admin/**`와 `/v1/admin/**` 인가 판정을 담당한다.
- `X-User-Id`, `X-Original-Method`, `X-Original-Path`를 필수 입력으로 유지한다.
- `GET /health`와 `GET /ready`는 운영 점검 기준으로 유지한다.
- 권한의 진실은 authz-server, 공개 여부는 user-service, 최종 집행은 소비자 서비스가 담당한다.
- v2는 권한 조회/검증 API, policy-based authorization, authz cache, 권한 변경 이벤트, 권한 versioning, 감사 강화, 세분화된 관리자 권한을 포함한다.

## v2 Notes
- 권한 조회는 role, scope, tenant, entitlements 스냅샷을 반환한다.
- 정책 검증은 `resource + action + condition` 모델을 사용한다.
- 토큰 클레임에는 `roles`, `scopes`, `tenant`, `entitlements`, `authz_version`을 반영할 수 있다.
- 권한 변경 이벤트는 role 부여/회수, 그룹 변경, 정책 변경을 모두 포함한다.
- 관리자 권한은 운영자, 보안관리자, 감사자처럼 세분화할 수 있다.
- introspect는 토큰 유효성과 현재 권한 유효성을 함께 확인한다.

## Validation
- Commands:
  - `./gradlew bootRun`
  - `curl -i http://localhost:8084/health`
  - `curl -i http://localhost:8084/ready`
  - `curl -i -X POST http://localhost:8084/permissions/internal/admin/verify -H 'X-User-Id: admin-seed' -H 'X-Original-Method: GET' -H 'X-Original-Path: /v1/admin/blocks' -H 'X-Request-Id: debug-req-1' -H 'X-Correlation-Id: debug-corr-1'`
  - `curl -i -X POST http://localhost:8084/v2/permissions/authorize -H 'Content-Type: application/json' -d '{"userId":"user-123","resource":"admin:dashboard","action":"read","condition":{"tenant":"tenant-a"}}'`
  - `curl -i http://localhost:8084/v2/permissions/users/user-123`
  - `curl -i -X POST http://localhost:8084/v2/permissions/internal/introspect`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<routing, headers, ...>` | `<short note>` |
