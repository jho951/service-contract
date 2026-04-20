# 환경변수

## 기본 런타임
- `GATEWAY_BIND=0.0.0.0`
- `GATEWAY_PORT=8080`
- `GATEWAY_REQUEST_TIMEOUT_MS=30000`
- `GATEWAY_LOGIN_RATE_LIMIT_PER_MINUTE=20`
- `GATEWAY_MAX_BODY_BYTES=1048576`

## 라우팅 및 프록시
- `AUTH_SERVICE_URL=http://auth-service:8081`
- `USER_SERVICE_URL=http://user-service:8082`
- `BLOCK_SERVICE_URL=http://documents-service:8083`
- `PERMISSION_SERVICE_URL=http://authz-service:8084`
- `PERMISSION_ADMIN_VERIFY_URL=http://authz-service:8084/permissions/internal/admin/verify`
- `REDIS_HOST=central-redis`
- `REDIS_PORT=6379`
- `GATEWAY_CORS_ALLOWED_ORIGINS=*`
- `GATEWAY_FORWARD_AUTHORIZATION_HEADER=false`
- `REDIS_PASSWORD`와 `REDIS_TIMEOUT_MS`는 Redis 연결 안정화를 위한 선택값이다.
- 코드 기본값은 `REDIS_HOST=127.0.0.1`이지만, Docker/compose 기본값은 `central-redis`다.
- `GATEWAY_FORWARD_AUTHORIZATION_HEADER`는 현재 핸들러의 주요 경로에서는 사용되지 않고, 호환성/전환용 설정으로 남아 있다.
- 현재 구현은 외부 `Authorization`을 그대로 전달하지 않고 제거한 뒤, 인증 성공 시 내부 JWT만 다시 넣는다.

## JWT 선검증
JWT를 완전 검증하기 전에 Gateway가 먼저 수행하는 얕은 검증 설정이다.

### `GATEWAY_JWT_PRECHECK_EXP_ENABLED`
- 타입: `boolean`
- 기본값: `false`
- 설명:
  - `true`면 `exp`가 만료된 토큰을 Gateway 단계에서 먼저 거른다.
  - `false`면 exp 선검증을 건너뛴다.

### `GATEWAY_JWT_PRECHECK_EXP_CLOCK_SKEW_SECONDS`
- 타입: `number`
- 기본값: `30`
- 설명:
  - `exp` 선검증에서 허용하는 시계 오차 범위이다.

### `GATEWAY_JWT_PRECHECK_MAX_TOKEN_LENGTH`
- 타입: `number`
- 기본값: `4096`
- 설명:
  - 선검증 단계에서 허용하는 Bearer 토큰 최대 길이이다.

### `GATEWAY_USER_ID_CLAIMS`
- 타입: `csv`
- 기본값: `sub,userId`
- 설명:
  - Gateway가 토큰에서 사용자 ID를 추출할 때 참조하는 클레임 목록이다.
  - 앞쪽 값부터 우선한다.

## 세션 캐시
Bearer 토큰 검증 결과를 캐싱할 때 사용하는 설정이다.

### `GATEWAY_SESSION_CACHE_ENABLED`
- 타입: `boolean`
- 기본값: `true`

### `GATEWAY_SESSION_LOCAL_CACHE_TTL_SECONDS`
- 타입: `number`
- 기본값: `3`

### `GATEWAY_SESSION_CACHE_TTL_SECONDS`
- 타입: `number`
- 기본값: `60`

### `GATEWAY_SESSION_CACHE_KEY_PREFIX`
- 타입: `string`
- 기본값: `gateway:session:`

## 권한 / 관리자 정책
### `GATEWAY_PERMISSION_CACHE_TTL_SECONDS`
- 타입: `number`
- 기본값: `300`

### `GATEWAY_PERMISSION_CACHE_ENABLED`
- 타입: `boolean`
- 기본값: `false`
- 설명:
  - `true`면 관리자 경로 판정 결과를 짧게 캐시한다.
  - `false`면 Authz에 매번 위임한다.

### `GATEWAY_PERMISSION_CACHE_PREFIX`
- 타입: `string`
- 기본값: `gateway:admin-permission:`

### `PERMISSION_SERVICE_URL`
- 타입: `string`
- 기본값: `http://authz-service:8084`
- 설명:
  - 관리자 경로 인가 판정용 Authz 기본 URI다.

### `PERMISSION_ADMIN_VERIFY_URL`
- 타입: `string`
- 기본값: `http://authz-service:8084/permissions/internal/admin/verify`
- 설명:
  - Gateway가 관리자 경로 판정을 위임할 때 호출하는 실제 엔드포인트다.

## IP Guard
### `GATEWAY_IP_GUARD_ENABLED`
- 타입: `boolean`
- 기본값: `true`

### `GATEWAY_ALLOWED_IPS`
- 타입: `csv`
- 기본값: `*`

### `GATEWAY_IP_GUARD_DEFAULT_ALLOW`
- 타입: `boolean`
- 기본값: `false`

### `GATEWAY_INTERNAL_IP_GUARD_ENABLED`
- 타입: `boolean`
- 기본값: `true`

### `GATEWAY_INTERNAL_ALLOWED_IPS`
- 타입: `csv`
- 기본값: `127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16`

### `GATEWAY_INTERNAL_IP_GUARD_DEFAULT_ALLOW`
- 타입: `boolean`
- 기본값: `false`

### `GATEWAY_ADMIN_IP_GUARD_ENABLED`
- 타입: `boolean`
- 기본값: `true`

### `GATEWAY_ADMIN_ALLOWED_IPS`
- 타입: `csv`
- 기본값: `127.0.0.1`

### `GATEWAY_ADMIN_IP_GUARD_DEFAULT_ALLOW`
- 타입: `boolean`
- 기본값: `false`

## 내부 JWT / INTERNAL 시크릿
### `GATEWAY_INTERNAL_JWT_SHARED_SECRET`
- 타입: `string`
- 기본값: 없음
- 설명:
  - Gateway가 내부 서비스로 넘기는 JWT 서명용 비밀키이다.
  - 비워 두면 `AUTH_JWT_SHARED_SECRET`를 재사용하고, 그것도 없으면 개발용 기본값을 사용한다.

### `GATEWAY_INTERNAL_JWT_ISSUER`
- 타입: `string`
- 기본값: `api-gateway`

### `GATEWAY_INTERNAL_JWT_AUDIENCE`
- 타입: `string`
- 기본값: `internal-services`

### `GATEWAY_INTERNAL_JWT_TTL_SECONDS`
- 타입: `number`
- 기본값: `300`

### `GATEWAY_INTERNAL_REQUEST_SECRET`
- 타입: `string`
- 기본값: 없음
- 설명:
  - `INTERNAL` 라우트 허용 여부를 판정하는 공유 시크릿이다.
  - 비워 두면 `GATEWAY_INTERNAL_JWT_SHARED_SECRET`를 재사용한다.

## JWT 검증 설정
### `AUTH_JWT_VERIFY_ENABLED`
- 타입: `boolean`
- 기본값: `false`
- 설명:
  - `true`면 Gateway가 auth-service 토큰의 서명/클레임 검증을 시도한다.
  - `false`면 인증 전 JWT 검증을 건너뛴다.
- 비고:
  - 운영 환경에서는 `true`를 권장한다.
  - 개발 환경에서만 `false` 사용을 고려한다.
  - `true`로 두었는데 공개키/공유키가 없으면 Gateway는 설정 오류로 시작에 실패한다.

### `AUTH_JWT_PUBLIC_KEY_PEM`
- 타입: `string`
- 설명:
  - auth-service가 발행한 JWT를 RSA 계열(`RS256`, `RS384`, `RS512`)로 검증할 때 사용하는 공개키 PEM 문자열이다.
- 입력 예시:
  ```env
  AUTH_JWT_PUBLIC_KEY_PEM="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
  ```
- 비고:
  - 여러 줄 PEM은 `\n`을 포함한 한 줄 문자열로 전달해야 한다.

### `AUTH_JWT_SHARED_SECRET`
- 타입: `string`
- 설명:
  - auth-service JWT를 HS 계열(`HS256`, `HS384`, `HS512`)로 검증할 때 사용하는 대칭 키이다.
- 필수 조건:
  - `AUTH_JWT_ALGORITHM`이 `HS*`면 반드시 설정해야 한다.

### `AUTH_JWT_KEY_ID`
- 타입: `string`
- 기본값: 없음
- 설명:
  - JWT 헤더의 `kid`와 비교하는 키 식별자이다.
  - 특정 키만 허용하고 싶을 때 사용한다.

### `AUTH_JWT_ALGORITHM`
- 타입: `string`
- 기본값: `RS256`
- 허용 값:
  - `RS256`
  - `RS384`
  - `RS512`
  - `HS256`
  - `HS384`
  - `HS512`
- 설명:
  - Gateway가 기대하는 JWT 서명 알고리즘이다.

### `AUTH_JWT_ISSUER`
- 타입: `string`
- 기본값: 없음
- 설명:
  - JWT의 `iss` 클레임이 이 값과 일치해야 인증이 통과한다.
  - 비워 두면 issuer 검증을 수행하지 않는다.

### `AUTH_JWT_AUDIENCE`
- 타입: `string`
- 기본값: 없음
- 설명:
  - 선택 항목이다.
  - 비워 두면 `aud` 검증을 수행하지 않는다.
  - 값이 있으면 JWT의 `aud` 클레임에 해당 값이 포함되어야 한다.

### `AUTH_JWT_CLOCK_SKEW_SECONDS`
- 타입: `number`
- 기본값: `30`
- 설명:
  - `exp` 검증 시 허용하는 시계 오차 범위이다.

## OAuth 디버그 로그
### `GATEWAY_OAUTH_DEBUG_LOG_ENABLED`
- 타입: `boolean`
- 기본값: `false`
- 설명:
  - `true`면 OAuth 흐름 관련 요청/응답 추적 로그를 남긴다.
  - 다음 경로에 대해 `oauth_trace` 로그를 INFO 레벨로 출력한다.
    - `/v1/auth/sso/start`
    - `/v1/oauth2/**`
    - `/v1/login/oauth2/**`
    - `/v1/auth/exchange`
- 비고:
  - 쿠키 값, 코드 값 같은 민감 정보는 출력하지 않는다.
  - 존재 여부와 흐름만 로그로 남긴다.

## 감사 로그
### `GATEWAY_AUDIT_LOG_ENABLED`
- 타입: `boolean`
- 기본값: `true`

### `GATEWAY_AUDIT_LOG_PATH`
- 타입: `string`
- 기본값: `./logs/audit.log`

### `GATEWAY_AUDIT_SERVICE_NAME`
- 타입: `string`
- 기본값: `gateway-service`

### `APP_ENV`
- 타입: `string`
- 기본값: `local`

### `GATEWAY_AUDIT_LOG_ASYNC_ENABLED`
- 타입: `boolean`
- 기본값: `true`

### `GATEWAY_AUDIT_LOG_ASYNC_THREADS`
- 타입: `number`
- 기본값: `2`

## 운영 권장값
- `AUTH_JWT_VERIFY_ENABLED=true`
- `AUTH_JWT_ALGORITHM`은 실제 auth-service 설정과 일치시킨다
- RSA 계열이면 `AUTH_JWT_PUBLIC_KEY_PEM` 설정
- HS 계열이면 `AUTH_JWT_SHARED_SECRET` 설정
- `PERMISSION_SERVICE_URL=http://authz-service:8084`
- `PERMISSION_ADMIN_VERIFY_URL=http://authz-service:8084/permissions/internal/admin/verify`
- `AUTH_JWT_AUDIENCE`는 정책이 있으면 명시, 없으면 비움
- 운영 환경에서는 `GATEWAY_INTERNAL_REQUEST_SECRET`과 IP guard 목록도 명시하는 것이 좋다.

## 개발 환경
- 필요 시 `AUTH_JWT_VERIFY_ENABLED=false`
- OAuth 흐름 디버깅이 필요할 때만 `GATEWAY_OAUTH_DEBUG_LOG_ENABLED=true`
- 로컬에서는 `GATEWAY_INTERNAL_JWT_SHARED_SECRET`와 `GATEWAY_INTERNAL_REQUEST_SECRET`이 비어 있어도 개발 기본값으로 동작할 수 있다.
