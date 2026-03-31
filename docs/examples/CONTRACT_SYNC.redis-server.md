# CONTRACT_SYNC.md

## Repository
- Repo: `https://github.com/jho951/Redis-server`
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
- `contracts/common/service-ownership.md`
- `contracts/common/adoption-matrix.md`
- `contracts/redis/README.md`
- `contracts/redis/keys.md`
- `contracts/redis/security.md`
- `contracts/redis/ops.md`
- `contracts/gateway/cache.md`
- `contracts/gateway/env.md`
- `contracts/permission/README.md`
- `contracts/permission/ops.md`
- `contracts/permission/security.md`
- `contracts/openapi/*.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
  - `redis`
  - `redis-keys`
  - `redis-security`
  - `redis-ops`
  - `cache`
  - `env`
  - `service-ownership`
  - `adoption-matrix`
  - `gateway-cache`
  - `permission-ops`
  - `openapi`
- Affected Endpoints or Flows:
  - `gateway:session: key namespace`
  - `gateway:admin-permission: key namespace`
  - `permission:* key namespace`
  - `Redis connectivity / readiness`

## Service Notes
- Redis는 HTTP API를 노출하지 않는다.
- `gateway:session:`과 `gateway:admin-permission:` prefix는 Gateway 소유다.
- `permission:*` prefix는 Authz-server 보조 캐시용이다.
- `gateway:session:<hash>`는 인증 성공 결과를, `gateway:admin-permission:<hash>`는 관리자 판정 결과를 저장한다.
- Redis 장애 시 각 서비스의 fail-open/fail-closed 정책은 서비스 contract를 따른다.

## Validation
- Commands:
  - `redis-cli -h localhost -p 6379 PING`
  - `redis-cli -h localhost -p 6379 -a <password> PING`
  - `redis-cli -h localhost -p 6379 SCAN 0 MATCH 'gateway:*' COUNT 10`
  - `redis-cli -h localhost -p 6379 SCAN 0 MATCH 'permission:*' COUNT 10`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<redis, redis-keys, redis-security, redis-ops, cache, env>` | `<short note>` |
