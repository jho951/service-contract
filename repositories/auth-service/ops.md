# Auth Operations Contract

## Runtime Role
- Auth-service는 Gateway 뒤에서 동작하는 인증 원천 서비스다.
- 직접 public `/v1/auth/*`를 받지 않는다.
- Gateway는 public route를 `/auth/*` upstream route로 변환한다.
- 운영 환경에서는 JWT 발급 설정과 Gateway 검증 설정이 일치해야 한다.

## Required Dependencies
| Dependency | Purpose | Failure impact |
| --- | --- | --- |
| MySQL | auth account, login attempt, MFA factor 저장 | login/internal account 실패 |
| Redis | refresh/session/SSO state 저장 | refresh, SSO, session validation 실패 |
| User-service | SSO provisioning, user status/profile lookup | SSO 또는 `/auth/me` 실패 |
| Gateway | public routing, CORS, auth channel selection | 외부 client 접근 실패 |

## Startup Checks
- `GET /`가 `service=auth-service`, `status=UP`를 반환한다.
- `GET /v1`도 같은 status alias를 반환한다.
- `GET /.well-known/jwks.json`이 현재 JWT 알고리즘 정책과 맞게 응답한다.
- Redis 연결이 refresh/session store와 연결되어 있다.
- MySQL schema가 현재 entity와 맞는다.

## Smoke Validation
Auth-service를 직접 확인할 때는 upstream route를 사용한다.

```bash
curl -i http://localhost:8081/
curl -i http://localhost:8081/v1
curl -i http://localhost:8081/.well-known/jwks.json
curl -i -X POST http://localhost:8081/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"user@example.com","password":"password1234"}'
curl -i -X POST http://localhost:8081/auth/refresh
curl -i -X POST http://localhost:8081/auth/logout
```

Gateway 경유 확인은 Gateway public route를 사용한다.

```bash
curl -i -X POST http://localhost:8080/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"user@example.com","password":"password1234"}'
```

## Operational Flows
### Login
- credential 검증 실패가 증가하면 `9101`, `9113`, login attempt 기록을 먼저 본다.
- 계정 잠금이 발생하면 failed login count와 account lock policy를 확인한다.

### Refresh
- refresh 실패는 cookie/header 누락, 만료, revoke, Redis 연결 문제로 나눠 본다.
- refresh token rotation 정책과 cookie domain/path 설정을 함께 확인한다.

### Logout
- 현재 등록된 `/auth/logout`은 SSO session revoke와 cookie clear를 기준으로 확인한다.
- refresh token 저장소 revoke까지 요구하는 릴리스라면 auth-service 구현에서 token logout flow가 실제 controller에 연결되어 있는지 확인한다.

### SSO
- provider redirect 실패와 ticket exchange 실패를 분리해서 본다.
- GitHub callback URI는 Gateway public callback과 Spring Security callback mapping이 일치해야 한다.
- `admin` page SSO는 IP guard 설정을 확인한다.

### Internal Account
- 계정 생성 실패는 duplicate login id, duplicate user id, password validation, MySQL constraint를 확인한다.
- User-service와 Auth-service 간 rollback 정책을 같이 확인한다.

## Error Triage
- `9005`: 이미 존재하는 auth account
- `9006`: auth account 없음
- `9007`: User-service 연동 실패
- `9101`: 인증 필요
- `9111`: invalid token
- `9112`: expired token
- `9113`: login required
- `9105`, `9106`: upstream timeout/failure

## Release Checklist
- Auth-service upstream API가 [api.md](api.md)와 맞는다.
- Gateway route mapping이 [../gateway-service/auth-proxy.md](../gateway-service/auth-proxy.md)와 맞는다.
- OpenAPI 경로가 public-facing인지 upstream-facing인지 문서에 표시되어 있다.
- Auth-service `contract.lock.yml`에는 upstream 계약과 실제 소비하는 OpenAPI만 남긴다.
- JWT key, issuer, audience, cookie policy가 환경별 설정과 맞는다.
