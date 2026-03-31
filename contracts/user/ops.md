# User Operations Contract

## Startup / Runtime
- user-service는 공개 사용자 가입과 내부 사용자 연동의 기준 서비스다.
- `users/me` 는 Gateway 재주입 또는 JWT 인증이 함께 동작해야 한다.
- 내부 API는 `GatewayUserPrincipal` 또는 내부 JWT 컨텍스트를 신뢰한다.
- 공개 API는 기능 플래그로 꺼질 수 있다.

## Operational Flows
- signup 후에는 user 생성 응답과 상태를 검증한다.
- social create / ensure-social / find-or-create-and-link-social 는 멱등성 관점에서 운영한다.
- 상태 변경은 관리자/내부 운영 흐름에서만 발생한다.

## Maintenance
- 사용자 상태(`ACTIVE`, `PENDING`, `SUSPENDED`, `DELETED` 등)는 다운스트림 정책과 일치해야 한다.
- 소셜 provider alias(`provider`, `providerUserId`) 는 내부 정규화 규칙에 맞춘다.
- 오류 증가 시 `7100~7102`, `7200~7202`, `7099` 계열을 먼저 본다.

## Validation
- `/users/signup`
- `/users/me`
- `/internal/users`
- `/internal/users/social`
- `/internal/users/ensure-social`
- `/internal/users/find-or-create-and-link-social`
- `/internal/users/{userId}/status`
- `/internal/users/{userId}`
- `/internal/users/by-email`
- `/internal/users/by-social`

## Notes
- 공개 API는 Gateway 경유를 기본으로 한다.
- 내부 사용자 식별은 `X-User-Id`와 내부 JWT를 기준으로 한다.
