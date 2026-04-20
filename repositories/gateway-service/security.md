# Gateway Security

## 신뢰 경계
- 외부 `X-User-Id`는 신뢰하지 않는다.
- 외부 `X-Client-Type`은 신원 식별값이 아니다.
- 외부 `Authorization`은 제거하고 내부 JWT만 재주입한다.
- downstream은 Gateway가 재주입한 값만 신뢰한다.

## 라우트 보안
- `INTERNAL` 라우트는 `X-Internal-Request-Secret`이 필요하다.
- `ADMIN` 라우트는 IP guard를 적용한다.
- `ADMIN` 라우트는 Authz 인가 판정을 통과해야 한다.
- 로그인 경로는 rate limit을 적용한다.
- `OPTIONS`와 `GET /v1/health`, `GET /v1/ready`는 예외 경로다.
- Gateway의 허용/거부, IP 차단, 헤더 정규화 실패는 `audit-log` 공통 모듈로 발행한다.

## 전송 보안
- CORS는 Gateway에서 단일 처리한다.
- `Origin` / `Referer` / `User-Agent`는 채널 판별 보조 신호다.
- 내부 서비스는 서비스 레벨 CORS를 비활성화하는 편이 안전하다.

## 내부 JWT
- Gateway는 성공한 인증 결과를 내부 JWT로 다시 발급한다.
- 내부 JWT는 downstream 서비스의 최종 신뢰 토큰이다.
- 관리자 경로의 최종 허용 여부는 Authz의 `200/403` 결과를 따른다.
