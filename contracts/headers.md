# Header Contract

## Trace Headers
- `X-Request-Id` (필수 전파)
- `X-Correlation-Id` (필수 전파)

Gateway는 위 헤더를 생성/전달하고, downstream은 로그 상관관계 키로 사용합니다.

## Trusted Headers
외부 요청의 trusted 헤더는 Gateway에서 제거 후 재주입합니다.

- `X-User-Id`
- `X-User-Role`
- `X-Session-Id`
- `X-Request-Id`
- `X-Correlation-Id`

Downstream 서비스는 gateway가 재주입한 값만 신뢰합니다.

## Internal Secret Header
- `X-Internal-Request-Secret`
- 용도: Gateway INTERNAL 라우트 1차 차단
- 권장: 서비스에서도 2차 보호(내부 JWT + scope 검증 필수)
