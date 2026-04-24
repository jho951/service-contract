# Auth Contract

`auth-service`는 인증 원천 서비스다. 사용자가 누구인지 확인하고, access token / refresh token / browser session을 발급하거나 검증한다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/auth-service |
| Branch | `main` |
| Contract Lock | `contract.lock.yml` |

## 한 줄 요약
- Client가 보는 public route versioning은 Gateway가 담당한다.
- Auth-service가 직접 받는 upstream route는 `/auth/*`와 `/internal/auth/*`다.
- Auth-service는 권한 판단을 하지 않는다. 최종 인가는 authz-service가 담당한다.
- User profile의 공개 범위와 social profile ownership은 user-service가 담당한다.

## 책임 경계
| 영역 | 책임 서비스 | 설명 |
| --- | --- | --- |
| Public route versioning | Gateway | `/v1/auth/*`, `/v2/auth/*` 같은 외부 경로를 소유한다. |
| Authentication | Auth-service | 로그인, refresh, logout, SSO, token/session 발급과 검증을 소유한다. |
| Authorization | Authz-service | 관리자 접근, capability, policy 판단을 소유한다. |
| User profile | User-service | 사용자 프로필, 상태, visibility/privacy를 소유한다. |

## 경로 모델
Gateway는 외부 요청을 받은 뒤 Auth-service upstream 경로로 변환한다.

| Client public route | Auth-service upstream route |
| --- | --- |
| `POST /v1/auth/login` | `POST /auth/login` |
| `POST /v1/auth/refresh` | `POST /auth/refresh` |
| `POST /v1/auth/logout` | `POST /auth/logout` |
| `GET /v1/auth/sso/start` | `GET /auth/sso/start` |
| `GET /v1/auth/oauth2/authorize/{provider}` | `GET /auth/oauth2/authorize/{provider}` |
| `POST /v1/auth/exchange` | `POST /auth/exchange` |
| `GET /v1/auth/me` | `GET /auth/me` |

Auth-service는 `/v1/auth/*` 또는 `/v2/auth/*`를 직접 소유하지 않는다. v2 public route도 같은 원칙을 따른다.

## 현재 지원 범위
아래 목록은 auth-service 현재 구현을 기준으로 한 upstream API다.

### Token
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/logout`

### SSO
- `GET /auth/sso/start`
- `GET /auth/login/github`
- `GET /auth/oauth2/authorize/{provider}`
- `GET /auth/oauth/github/callback`
- `POST /auth/exchange`

현재 provider는 GitHub를 기준으로 한다. provider 확장은 v2 계획에 포함된다.

### Session / Current User
- `POST /auth/internal/session/validate`
- `GET /auth/session`
- `GET /auth/me`

### Internal Account
- `POST /internal/auth/accounts`
- `DELETE /internal/auth/accounts/{userId}`

내부 계정 생성은 `userId`, `loginId`, `password`를 받는다. `email` 단일 필드 생성 계약은 현재 구현 기준이 아니다.

### Runtime / Discovery
- `GET /`
- `GET /v1`
- `GET /.well-known/jwks.json`

`GET /v1`은 service status alias다. public auth route versioning과는 별개의 runtime 호환 경로다.

## 주요 흐름
### Password Login
1. Client가 Gateway의 `POST /v1/auth/login`을 호출한다.
2. Gateway가 Auth-service의 `POST /auth/login`으로 전달한다.
3. Auth-service가 credential을 검증하고 token을 발급한다.
4. Browser 요청이면 cookie도 함께 설정될 수 있다.
5. Gateway는 응답을 public contract에 맞춰 client에 전달한다.

### Refresh
1. Client가 Gateway의 `POST /v1/auth/refresh`를 호출한다.
2. Gateway가 Auth-service의 `POST /auth/refresh`로 전달한다.
3. Auth-service가 refresh token을 cookie 또는 header에서 추출한다.
4. Auth-service가 새 access token / refresh token을 발급한다.

### GitHub SSO
1. Client가 Gateway의 SSO 시작 경로를 호출한다.
2. Gateway가 Auth-service의 `/auth/sso/start` 또는 `/auth/oauth2/authorize/github`로 전달한다.
3. Auth-service가 GitHub OAuth flow를 시작한다.
4. callback 이후 Auth-service가 일회용 ticket을 발급한다.
5. Client가 ticket을 `/auth/exchange` 흐름으로 교환해 session/token을 받는다.

### Logout
1. Client가 Gateway의 `POST /v1/auth/logout`을 호출한다.
2. Gateway가 Auth-service의 `POST /auth/logout`으로 전달한다.
3. Auth-service는 `sso_session`이 있으면 session store에서 revoke한다.
4. Auth-service는 `sso_session`, `ACCESS_TOKEN`, refresh token cookie 제거 header를 내려준다.
5. 현재 구현 기준으로 refresh token의 서버 저장소 revoke는 별도 token logout controller에 연결되어 있지 않다.

### Session Validation
1. Gateway가 보호 route 처리 중 Auth-service session 검증을 호출한다.
2. Auth-service가 cookie session 또는 token context를 검증한다.
3. Gateway는 응답의 `userId`, `status`, `sessionId`로 내부 사용자 컨텍스트를 만든다.
4. 응답에 `role`이 존재하더라도 호환용 인증 메타데이터일 뿐, Gateway의 `X-User-Role` 생성이나 Authz 판정 입력으로 사용하지 않는다.

## Current Platform Runtime
- `auth-service` 현재 구현은 `platform-runtime-bom 3.0.1`, `platform-governance-bom 3.0.1`, `platform-security-bom 3.0.1`을 함께 사용한다.
- 런타임 모듈은 `platform-governance-starter`, `platform-security-starter`, `platform-security-auth-bridge-starter`, `platform-security-ratelimit-bridge-starter`, `platform-security-governance-bridge`다.
- `AuthPlatformIssuerAdaptersConfiguration`이 raw `TokenService`, `SessionStore` adapter를 제공하고 bridge starter가 이를 platform issuer/session 확장으로 연결한다.
- `SecurityConfig`는 `PlatformSecurityRequestAttributeBridgeFilter`와 `securityServletFilter`를 함께 넣어 cookie/session과 internal caller proof를 request attribute로 브리지한다.
- 운영 감사 전달은 service-owned `AuditSink` bean이 맡는다.

## 문서 맵
- [API Contract](api.md): 현재 upstream API와 request/response shape
- [v2 Design](v2.md): MFA, step-up, provider 확장, session lifecycle 계획
- [Security Contract](security.md): trust boundary, token/session 정책

## 운영 배포 자산

- EC2 image-only 배포 기준 산출물은 구현 repo의 `deploy/ec2/` 아래에 둔다.
- 기본 파일은 `docker-compose.yml`, `.env.production.example`, `README.md`이고, 현재 구현은 MySQL init/schema 보조 파일도 함께 포함한다.
- [Operations Contract](ops.md): 운영 점검과 smoke validation
- [Error Contract](errors.md): auth-service error code
- [Gateway Auth Proxy](../gateway-service/auth-proxy.md): public route와 upstream route 매핑
- [Auth Upstream OpenAPI v1](../../artifacts/openapi/auth-service.upstream.v1.yaml)

## 계약 원칙
- Auth-service는 인증 원천이다.
- Auth-service는 public API version prefix에 결합하지 않는다.
- Gateway는 외부 route versioning, 인증 채널 판정, 사용자 컨텍스트 재주입을 담당한다.
- 브라우저는 cookie 기반 흐름을 우선하고, 비브라우저는 Bearer token 흐름을 우선한다.
- 내부 경로는 내부 JWT, 내부 secret, Gateway 재주입 컨텍스트처럼 명시된 신뢰 수단만 허용한다.
- Auth-service 이벤트는 audit-log 계약을 따른다.
