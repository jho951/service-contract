# README Contract Source Section

Use one of these blocks near the top of the backend service README files.

## auth-service
```md
## Contract Source
- Contract Repo: https://github.com/jho951/service-contract
- Contract Lock: `contract.lock.yml`
- Repo Role: backend service
- Branch: main

## Contract Scope
- Login, refresh, logout
- SSO start, OAuth2 authorize, exchange, callback
- Session validate, session alias, me
- Internal auth account create/delete
- Runtime status and JWKS discovery
- v2: MFA / step-up, multi-provider SSO, session inventory, account policy, internal management API
- v2 OpenAPI draft: `artifacts/openapi/auth-service.v2.yaml`
- audit events: `shared/audit.md`
```

## authz-service
```md
## Contract Source
- Contract Repo: https://github.com/jho951/service-contract
- Contract Lock: `contract.lock.yml`
- Repo Role: backend service
- Branch: main

## Contract Scope
- Gateway admin authorization for `/admin/**` and `/v1/admin/**`
- `POST /permissions/internal/admin/verify`
- `GET /health`, `GET /ready`
- RBAC policy evaluation and audit logging
- v2: authorization queries, policy-based authz, token claims sync, authz cache, versioning, delegation
- v2 docs: `repositories/authz-service/policy-model.md`, `repositories/authz-service/policy-engine.md`, `repositories/authz-service/delegation.md`, `repositories/authz-service/versioning.md`, `repositories/authz-service/introspection.md`, `repositories/authz-service/cache.md`, `repositories/authz-service/external-boundaries.md`
- v2 OpenAPI draft: `artifacts/openapi/authz-service.v2.yaml`
- audit events: `shared/audit.md`
```

## redis-service
```md
## Contract Source
- Contract Repo: https://github.com/jho951/service-contract
- Contract Lock: `contract.lock.yml`
- Repo Role: backend service
- Branch: main

## Contract Scope
- Central cache storage for gateway session and admin permission cache
- Redis key namespace and TTL policy
- Connectivity, readiness, and operational validation
- audit events: `shared/audit.md`
```

## user-service
```md
## Contract Source
- Contract Repo: https://github.com/jho951/service-contract
- Contract Lock: `contract.lock.yml`
- Repo Role: backend service
- Branch: main

## Contract Scope
- Public signup and me
- Internal user create, get, update status
- Social create, ensure-social, find-or-create-and-link-social
- By-email and by-social lookup
- Profile visibility/privacy and permission exposure policy
- GlobalResponse envelope and success code contract
- audit events: `shared/audit.md`
```

## Notes
- Keep this section near the top of the README, right after the project summary.
- Keep the pinned contract ref and consumed contract list in `contract.lock.yml`.
- If the service uses only a subset of the contract, list the specific docs and flows in `contract.lock.yml`.
