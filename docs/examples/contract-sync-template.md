# CONTRACT_SYNC.md Template

> Copy this file into each service or frontend repo as `CONTRACT_SYNC.md` and fill in the placeholders.

## Repository
- Repo: `<repo-url>`
- Branch: `<branch>`
- Role: `<backend-service|frontend-consumer>`

## Contract Source
- Contract Repo: `https://github.com/jho951/contract`
- Contract Commit SHA: `<contract-sha>`
- Latest Sync Date: `<YYYY-MM-DD>`

## Referenced Contract Docs
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
- `contracts/openapi/*.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
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
  - `user`
  - `user-visibility`
  - `redis`
  - `redis-keys`
  - `redis-security`
  - `redis-ops`
  - `auth-ops`
  - `auth-errors`
  - `authz-ops`
  - `authz-errors`
  - `user-ops`
  - `user-errors`
  - `service-ownership`
  - `adoption-matrix`
  - `errors`
  - `env`
  - `openapi`
- Affected Endpoints or Flows:
  - `<endpoint-or-ui-flow-1>`
  - `<endpoint-or-ui-flow-2>`

## Service/Frontend Notes
### Backend Service Repos
- `main` or `dev` branch must match the adoption-matrix branch.
- Keep implementation aligned with contract before merging service changes.

### Frontend Consumer Repos
- Keep API request/response shapes aligned with the contract and OpenAPI.
- Record the UI flow or page that depends on each contract change.
- If the frontend uses mock data or fallback behavior, document it here.

## Validation
- Commands:
  - `<smoke-or-test-command-1>`
  - `<smoke-or-test-command-2>`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<routing, headers, ...>` | `<short note>` |
