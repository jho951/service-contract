# Auth Contract

`Auth-server`의 서비스 계약 허브다.

## 서비스 책임
- 외부 인증: 로그인, 로그아웃, 토큰 갱신
- 브라우저 인증: SSO 시작, OAuth2 시작, ticket 교환, callback
- 세션 계약: 내부 세션 검증, 현재 사용자 조회
- 내부 연동: 계정 생성/삭제
- 런타임 메타: 루트 상태, JWKS 공개키 노출

## 세부 문서
- [API Contract](api.md)
- [v2 Design](v2.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Error Contract](errors.md)
- [Auth Service OpenAPI](../openapi/auth-service.v1.yaml)
- [Auth Service OpenAPI v2](../openapi/auth-service.v2.yaml)

## API 범위
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET /auth/sso/start`
- `GET /auth/login/github`
- `GET /auth/oauth2/authorize/{provider}`
- `GET /auth/oauth/github/callback`
- `POST /auth/exchange`
- `POST /auth/internal/session/validate`
- `GET /auth/session`
- `GET /auth/me`
- `POST /internal/auth/accounts`
- `DELETE /internal/auth/accounts/{userId}`
- `GET /`
- `GET /v1`
- `GET /.well-known/jwks.json`

## 계약 원칙
- 외부 인증은 Gateway를 경유하는 것을 기본으로 한다.
- 브라우저는 쿠키 기반 세션을, 비브라우저는 Bearer 기반 토큰을 사용한다.
- `internal` 경로는 내부 JWT 또는 Gateway 재주입 컨텍스트만 신뢰한다.
- auth-service는 토큰 발급 원천이며 Gateway는 사용자 컨텍스트를 정규화한다.
