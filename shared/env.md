# Environment Contract

## 운영 원칙
- 아래 `필수(Required)` 값은 정상 기능(인증/연동) 기준이며, 누락 시 부분 동작/오류가 발생할 수 있습니다.
- 로컬 개발에서는 일부 값이 fallback 기본값으로 대체될 수 있습니다.

## 네트워크
- `SHARED_SERVICE_NETWORK=service-backbone-shared`
- Gateway 전용 환경변수는 [repositories/gateway-service/env.md](../repositories/gateway-service/env.md)에서 관리한다.

## User Service
### 필수(Required)
- `USER_SERVICE_INTERNAL_JWT_ISSUER=auth-service`
- `USER_SERVICE_INTERNAL_JWT_AUDIENCE=user-service`
- `USER_SERVICE_INTERNAL_JWT_SECRET=<shared-secret>`
- `USER_SERVICE_INTERNAL_JWT_SCOPE=internal`

## Auth Service
### 필수(Required) - User 연동/내부 JWT
- `USER_SERVICE_BASE_URL=http://user-service:8082`
- `USER_SERVICE_JWT_ISSUER=auth-service`
- `USER_SERVICE_JWT_AUDIENCE=user-service`
- `USER_SERVICE_JWT_SUBJECT=auth-service`
- `USER_SERVICE_JWT_SCOPE=internal`
- `USER_SERVICE_JWT_SECRET=<shared-secret>`

### 필수(Required) - DB/Redis 기동
- `MYSQL_DB`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_URL`
- `REDIS_HOST`
- `REDIS_PORT`

### 선택(Optional) - SSO 사용 시 필수
- `SSO_GITHUB_CLIENT_ID`
- `SSO_GITHUB_CLIENT_SECRET`
- `SSO_GITHUB_CALLBACK_URI`
