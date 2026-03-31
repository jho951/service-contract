# Auth Operations Contract

## Startup / Runtime
- auth-service는 Gateway 앞단의 인증 원천 서비스다.
- 브라우저 로그인, refresh, SSO, session validate 흐름이 모두 auth-service를 지난다.
- 운영 시 JWT 서명 키와 JWKS 노출이 일치해야 한다.
- `GET /` 와 `GET /v1` 은 UP 상태 확인용이다.
- `/.well-known/jwks.json` 은 공개키 배포와 검증 기준이다.

## Operational Flows
- 로그인 성공 시 access token / refresh token / cookie가 함께 갱신될 수 있다.
- refresh 실패는 세션 무효화 또는 토큰 불일치로 이어질 수 있다.
- SSO 실패는 ticket 교환 단계와 provider redirect 단계로 구분해서 추적한다.

## Maintenance
- 계정 잠금 정책과 로그인 시도 기록을 유지한다.
- 내부 계정 생성/삭제는 user-service와의 연동 상태를 함께 확인한다.
- 오류 증가 시 `9105`, `9106`, `9007` 계열 upstream 오류를 먼저 본다.

## Validation
- `/auth/me`
- `/auth/session`
- `/auth/internal/session/validate`
- `/auth/login`
- `/auth/refresh`
- `/auth/logout`

## Notes
- 내부 엔드포인트는 Gateway 또는 내부 네트워크에서만 호출한다.
- auth-service가 발급한 토큰과 Gateway 재주입 컨텍스트는 같은 사용자 식별을 가리켜야 한다.
