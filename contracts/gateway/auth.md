# Gateway Authentication

## 인증 원칙
- 브라우저는 Cookie 기반 인증을 우선한다.
- 모바일/CLI/서버 간 호출은 Bearer 기반 인증을 우선한다.
- Gateway는 요청 채널을 먼저 판정한 뒤 그 채널의 인증 수단만 신뢰한다.

## 클라이언트 타입
- 권장 값
  - `web`
  - `native`
  - `cli`
  - `api`
- 허용 별칭
  - `web`, `browser`
  - `native`, `mobile`, `app`, `desktop`
  - `cli`
  - `api`, `service`, `server`

## 인증 선택 규칙
- `web` 판정이면 Cookie를 선택한다.
- `native` / `cli` / `api` 판정이면 Bearer를 선택한다.
- 둘 다 있으면 판정 결과를 따른다.
- `X-Client-Type`이 있지만 허용되지 않으면 `400 / 1002`다.
- 채널을 끝내 판정할 수 없으면 `400 / 1001`이다.

## 검증
### Cookie 경로
- `ACCESS_TOKEN`이 있으면 JWT 경로로 검증한다.
- `ACCESS_TOKEN`이 없으면 `sso_session` 쿠키를 auth-service에 검증 요청한다.

### Bearer 경로
- `GATEWAY_JWT_PRECHECK_*` 설정에 따라 얕은 선검증을 먼저 한다.
- `AUTH_JWT_VERIFY_ENABLED=true`면 서명/클레임 검증을 수행한다.
- `AUTH_JWT_ALGORITHM`은 `RS*` 또는 `HS*` 계열이어야 한다.
- `AUTH_JWT_ISSUER`, `AUTH_JWT_AUDIENCE`, `AUTH_JWT_KEY_ID`, `AUTH_JWT_CLOCK_SKEW_SECONDS`를 필요 시 적용한다.

## 인증 성공 결과
- `X-User-Id`를 내부 컨텍스트로 정규화한다.
- `X-User-Status`를 함께 정규화한다.
- 내부 JWT를 `Authorization`으로 다시 넣는다.
- 내부 서비스는 Gateway 재주입 값만 신뢰한다.

## 관리자 경로
- `ADMIN` 라우트는 인증 성공 후 authz-service 판정을 추가로 통과해야 한다.
- Gateway는 authz-service가 거부한 관리자 요청을 업스트림으로 전달하지 않는다.
