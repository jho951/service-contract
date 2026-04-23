# Gateway Auth Proxy

## 목적
Gateway가 요청 채널에 따라 인증 수단을 선택하고, 인증 결과를 내부 컨텍스트로 변환하는 흐름을 정리한다.

## Public Version Routing
Gateway는 외부 공개 API version prefix를 소유한다. Auth-service는 public `/v1` 또는 `/v2` prefix를 직접 처리하지 않고, Gateway가 upstream 경로로 변환한다.

| Public route | Upstream route | Owner |
| --- | --- | --- |
| `POST /v1/auth/login` | `POST /auth/login` | Gateway route versioning, auth-service authentication |
| `POST /v1/auth/refresh` | `POST /auth/refresh` | Gateway route versioning, auth-service token rotation |
| `POST /v1/auth/logout` | `POST /auth/logout` | Gateway route versioning, auth-service logout |
| `GET /v1/auth/sso/start` | `GET /auth/sso/start` | Gateway route versioning, auth-service SSO |
| `GET /v1/auth/oauth2/authorize/{provider}` | `GET /auth/oauth2/authorize/{provider}` | Gateway route versioning, auth-service SSO |
| `POST /v1/auth/exchange` | `POST /auth/exchange` | Gateway route versioning, auth-service SSO exchange |
| `GET /v1/auth/me` | `GET /auth/me` | Gateway route versioning, auth-service current user |

Public `/v2/auth/*` routes follow the same ownership model when enabled: Gateway owns the versioned public path, while auth-service owns the authentication behavior and upstream contract.

## 처리 순서
1. `Origin` / CORS 정책을 먼저 적용한다.
2. `OPTIONS` 요청은 `204 No Content`로 종료한다.
3. `GET /v1/health`, `GET /v1/ready`는 인증 없이 응답한다.
4. 라우트를 매칭한다.
5. `INTERNAL` / `ADMIN` / 로그인 경로 정책을 먼저 적용한다.
6. `PROTECTED` / `ADMIN` 라우트에서만 인증 선검사를 수행한다.
7. 요청 채널을 판정한다.
8. 채널에 맞는 인증 수단을 검증한다.
9. `ADMIN` 라우트는 인증 성공 후 Authz의 `POST /permissions/internal/admin/verify`를 호출한다.
10. 인증 성공 시 내부 JWT와 사용자 컨텍스트를 재주입한다.
11. 업스트림으로 프록시하고 성공 응답은 passthrough 한다.

## 채널 판정
- 1순위: `X-Client-Type`
- 2순위: `Origin` / `Referer`
- 3순위: `User-Agent`
- 4순위: endpoint fallback

## 채널별 인증 수단
### `web`
- `sso_session` 쿠키가 있으면 세션 검증 경로를 우선 사용한다.
- `sso_session`이 없고 `ACCESS_TOKEN` 쿠키가 있으면 JWT 검증 경로를 사용한다.
- 브라우저 요청에서 `Authorization`이 함께 와도 Cookie 계열이 우선이다.

### `native` / `cli` / `api`
- `Authorization: Bearer <token>`을 먼저 본다.
- JWT 선검증, 서명 검증, `iss` / `aud` / `exp` 검증을 수행한다.
- 필요 시 auth-service 세션 검증과 L1/L2 캐시를 사용한다.

## 내부 정규화
- 성공하면 `X-User-Id`, `X-User-Status`, `X-Client-Type`를 재주입한다.
- 성공하면 `iss=api-gateway`, `aud=internal-services` 계약의 내부 JWT를 `Authorization`으로 다시 넣는다.
- 외부 `Authorization`은 제거한다.
- `ADMIN` 라우트의 최종 허용 여부는 Authz 판정 결과를 따른다.
- Authz에는 `X-User-Id`, `X-Session-Id`, `X-Original-Method`, `X-Original-Path`, `X-Request-Id`, `X-Correlation-Id`를 전달한다.
- `X-User-Role` 같은 역할 헤더는 외부 입력에서 제거하며 Authz 판정 입력으로 사용하지 않는다.
