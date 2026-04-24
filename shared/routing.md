# Routing Contract

라우팅 계약의 핵심은 **public route는 Gateway가 소유하고, backend service는 upstream route만 소유한다**는 것이다.

## Route Layers
```txt
Client
  -> Gateway public route: /v1/**
  -> Service upstream route: service-owned path
```

| Layer | Owner | Example | Notes |
| --- | --- | --- | --- |
| Public route | Gateway | `/v1/auth/login` | client가 직접 호출하는 외부 계약 |
| Upstream route | Backend service | `/auth/login` | Gateway가 service로 전달하는 내부 계약 |
| Internal route | Backend service | `/internal/auth/accounts` | 서비스 간 호출 또는 운영용 |
| Runtime route | 각 서비스 | `/`, `/health`, `/ready`, `/.well-known/*` | 상태 확인/발견용 |

## Public Route Rules
- 외부 API는 Gateway의 `/v1/**` 또는 `/v2/**` 아래에 둔다.
- Backend service는 public version prefix를 직접 소유하지 않는다.
- Breaking change는 Gateway public route에서 version을 나눈다.
- Gateway는 필요하면 public request/response를 upstream 계약에 맞게 변환한다.

## Common Public Routes
| Public route | Route type | Upstream owner |
| --- | --- | --- |
| `GET /v1/health` | `PUBLIC` | Gateway |
| `GET /v1/ready` | `PUBLIC` | Gateway |
| `/v1/auth/**` | `PUBLIC` / `PROTECTED` | Auth-service |
| `/v1/users/**` | `PUBLIC` / `PROTECTED` | User-service |
| `/v1/internal/users/**` | `INTERNAL` | User-service |
| `/v1/workspaces/**` | `PROTECTED` | Editor/Block domain |
| `/v1/documents/**` | `PROTECTED` | Editor/Block domain |
| `/v1/admin/**` | `ADMIN` | Gateway + Authz |

## Upstream Mapping Examples
| Public route | Upstream route | Notes |
| --- | --- | --- |
| `POST /v1/auth/login` | `POST /auth/login` | Auth login |
| `POST /v1/auth/refresh` | `POST /auth/refresh` | Auth refresh |
| `POST /v1/auth/logout` | `POST /auth/logout` | Auth logout |
| `GET /v1/auth/me` | `GET /auth/me` | Current user |
| `GET /v1/users/me` | `GET /users/me` | User profile |
| `POST /v1/internal/users/find-or-create-and-link-social` | `POST /internal/users/find-or-create-and-link-social` | Internal user provisioning |

## Route Types
| Type | Meaning |
| --- | --- |
| `PUBLIC` | 인증 없이 접근 가능하거나 endpoint 자체가 인증 시작점 |
| `PROTECTED` | Gateway 인증 선검사 필요 |
| `ADMIN` | Gateway 인증 선검사 + Authz 관리자 검증 필요 |
| `INTERNAL` | 외부 직접 호출 금지, internal secret/JWT/scope 필요 |

## Upstream URL Rules
| Service | Env | Default |
| --- | --- | --- |
| Auth-service | `AUTH_SERVICE_URL` | `http://auth-service:8081` |
| User-service | `USER_SERVICE_URL` | `http://user-service:8082` |
| Editor service | `EDITOR_SERVICE_URL` | `http://editor-service:8083` |
| Authz admin verify | `AUTHZ_ADMIN_VERIFY_URL` | `http://authz-service:8084/permissions/internal/admin/verify` |

## Notes
- Gateway는 `/v1` prefix를 strip하거나 route별 rewrite를 적용해 upstream으로 전달한다.
- Upstream service 문서에는 public `/v1` prefix를 구현 요구사항처럼 적지 않는다.
- current gateway runtime은 editor upstream을 `EDITOR_SERVICE_URL` 하나로 읽는다.
- Authz는 code, 문서, prod compose 모두 `authz-service`를 canonical service key로 사용한다.
- Gateway는 현재 public `/v1/permissions/**`를 직접 proxy하지 않는다. `ADMIN` route 판정은 내부 `POST /permissions/internal/admin/verify` 호출로 수행한다.
- Runtime alias인 `GET /v1` 같은 서비스 내부 상태 경로는 public API versioning과 별개다.
