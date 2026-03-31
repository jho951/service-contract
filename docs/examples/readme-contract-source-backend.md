# README Contract Source Section

Use one of these blocks near the top of the backend service README files.

## Auth-server
```md
## Contract Source
- Contract Repo: https://github.com/jho951/contract
- Contract Sync: `CONTRACT_SYNC.md`
- Repo Role: backend service
- Branch: main

## Contract Scope
- Login, refresh, logout
- SSO start, OAuth2 authorize, exchange, callback
- Session validate, session alias, me
- Internal auth account create/delete
- Runtime status and JWKS discovery
- v2: MFA / step-up, multi-provider SSO, session inventory, account policy, internal management API
- v2 OpenAPI draft: `contracts/openapi/auth-service.v2.yaml`
```

## Authz-server
```md
## Contract Source
- Contract Repo: https://github.com/jho951/contract
- Contract Sync: `CONTRACT_SYNC.md`
- Repo Role: backend service
- Branch: main

## Contract Scope
- Gateway admin authorization for `/admin/**` and `/v1/admin/**`
- `POST /permissions/internal/admin/verify`
- `GET /health`, `GET /ready`
- RBAC policy evaluation and audit logging
- v2: authorization queries, policy-based authz, token claims sync, authz cache, versioning, delegation
- v2 docs: `contracts/authz/policy-model.md`, `contracts/authz/delegation.md`, `contracts/authz/versioning.md`, `contracts/authz/introspection.md`, `contracts/authz/cache.md`, `contracts/authz/external-boundaries.md`
- v2 OpenAPI draft: `contracts/openapi/authz-service.v2.yaml`
```

## Redis-server
```md
## Contract Source
- Contract Repo: https://github.com/jho951/contract
- Contract Sync: `CONTRACT_SYNC.md`
- Repo Role: backend service
- Branch: main

## Contract Scope
- Central cache storage for gateway session and admin permission cache
- Redis key namespace and TTL policy
- Connectivity, readiness, and operational validation
```

## User-server
```md
## Contract Source
- Contract Repo: https://github.com/jho951/contract
- Contract Sync: `CONTRACT_SYNC.md`
- Repo Role: backend service
- Branch: main

## Contract Scope
- Public signup and me
- Internal user create, get, update status
- Social create, ensure-social, find-or-create-and-link-social
- By-email and by-social lookup
- Profile visibility/privacy and permission exposure policy
- GlobalResponse envelope and success code contract
```

## Notes
- Keep this section near the top of the README, right after the project summary.
- Put detailed sync history and validation in `CONTRACT_SYNC.md`.
- If the service uses only a subset of the contract, list the specific flows in `CONTRACT_SYNC.md`.
