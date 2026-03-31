# Routing Contract

## 외부 경로 (Client -> Gateway)
- `/v1/health`
- `/v1/ready`
- `/v1/users/signup`
- `/v1/users/me`
- `/v1/internal/users/**` (외부 직접 호출 금지)
- `/v1/auth/**`
- `/v1/workspaces/**`
- `/v1/documents/**`
- `/v1/admin/**`

## 내부 경로 (Gateway -> Service)
Gateway는 `/v1` prefix를 strip 후 업스트림에 전달합니다.

- User Service
  - `/users/signup`
  - `/users/me`
  - `/internal/users/**`

## Route Type
- `PUBLIC`: 게이트웨이 JWT precheck 미적용
- `PROTECTED`: 게이트웨이 JWT precheck 적용
- `ADMIN`: 게이트웨이 JWT precheck + 관리자 정책
- `INTERNAL`: `X-Internal-Request-Secret` 통과 요청만 허용
- `GET /v1/health`, `GET /v1/ready`: 라우트 매칭보다 먼저 처리되는 health endpoint이며 인증 없이 즉시 응답

## 업스트림 주소 규칙
- `USER_SERVICE_URL=http://user-service:8082`
- `AUTH_SERVICE_URL=http://auth-service:8081`
- `BLOCK_SERVICE_URL=http://documents-service:8083`
