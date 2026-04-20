# Header Contract

## Trace Headers
- `X-Request-Id` (필수 전파)
- `X-Correlation-Id` (필수 전파)

Gateway는 위 헤더를 생성/전달하고, downstream은 로그 상관관계 키로 사용합니다.

## Trusted Headers
외부 요청의 trusted 헤더는 Gateway에서 제거 후 재주입합니다.

- `X-User-Id`
- `X-User-Status`
- `X-Session-Id`
- `X-Client-Type`
- `X-Request-Id`
- `X-Correlation-Id`

Downstream 서비스는 Gateway가 재주입한 값만 신뢰합니다.

현재 Gateway 구현은 인증 성공 후 `X-User-Id`, `X-User-Status`, `X-Client-Type`와 내부용 `Authorization`을 재주입합니다.

`X-User-Role`은 외부 요청에서 제거 대상이며, Authz 판정의 신뢰 입력으로 사용하지 않습니다. 권한/역할 조회와 최종 allow/deny 판단은 `X-User-Id`를 기준으로 authz-service가 수행합니다.

## Client Hint Headers
- `X-Client-Type`
- 용도: Gateway의 인증 채널 판별 힌트
- 권장 값: `web`, `native`, `cli`, `api`
- 허용 별칭: `browser`, `mobile`, `app`, `desktop`, `service`, `server`
- 주의: 외부 입력값은 신원 식별용 신뢰 헤더가 아니다
- Gateway가 내부로 재주입한 `X-Client-Type`만 downstream이 신뢰한다.

## Authorization
- 외부 요청의 `Authorization`은 신뢰하지 않는다.
- Gateway는 외부 `Authorization`을 먼저 제거한다.
- Gateway는 인증 성공 시 내부 JWT를 `Authorization`으로 다시 넣어 upstream에만 전달한다.
- downstream 서비스는 Gateway가 재주입한 내부 JWT만 검증한다.

## Internal Secret Header
- `X-Internal-Request-Secret`
- 용도: Gateway INTERNAL 라우트 1차 차단
- 권장: 서비스에서도 2차 보호(내부 JWT + scope 검증 필수)
