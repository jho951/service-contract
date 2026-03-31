# Auth API Contract

## Base Paths
- External/Gateway-facing: `/auth`
- Internal: `/internal/auth/accounts`
- Discovery/Runtime: `/`, `/v1`, `/.well-known/jwks.json`

## Token APIs

### `POST /auth/login`
- Request: `username`, `password`
- Response: `accessToken`, `refreshToken`
- 브라우저 경로에서는 쿠키가 함께 설정된다.

### `POST /auth/refresh`
- Request body 없음
- refresh token은 쿠키 또는 헤더에서 추출한다.
- Response: 새 `accessToken`, 새 `refreshToken`

### `POST /auth/logout`
- refresh token을 무효화하고 세션 쿠키를 제거한다.

## SSO APIs

### `GET /auth/sso/start`
### `GET /auth/login/github`
### `GET /auth/oauth2/authorize/{provider}`
- SSO/OAuth 시작 엔드포인트다.
- `page`, `redirect_uri` query를 지원한다.

### `GET /auth/oauth/github/callback`
- GitHub callback을 프론트 로그인 경로로 redirect 한다.

### `POST /auth/exchange`
- Request: `ticket`
- SSO ticket을 세션 또는 토큰으로 교환한다.

## Session APIs

### `POST /auth/internal/session/validate`
### `GET /auth/session`
- 내부 세션 검증 응답:
  - `authenticated`
  - `userId`
  - `role`
  - `status`
  - `sessionId`

### `GET /auth/me`
- 현재 사용자 요약 응답:
  - `id`
  - `email`
  - `name`
  - `avatarUrl`
  - `roles`
  - `status`

## Internal Account APIs

### `POST /internal/auth/accounts`
### `DELETE /internal/auth/accounts/{userId}`
- 내부 계정 생성/삭제에 사용한다.

## Discovery / Runtime APIs

### `GET /`
### `GET /v1`
- 서비스 상태 응답:
  - `service: auth-service`
  - `status: UP`

### `GET /.well-known/jwks.json`
- RSA 기반 JWT 검증용 공개키 집합을 제공한다.
- RSA 알고리즘이 아니거나 공개키가 없으면 빈 keys 배열을 반환한다.

## Contract Notes
- 외부 응답은 토큰 또는 사용자 요약 정보만 노출한다.
- 내부 검증 응답은 Gateway가 사용자 컨텍스트를 재구성할 수 있는 최소 정보만 반환한다.
