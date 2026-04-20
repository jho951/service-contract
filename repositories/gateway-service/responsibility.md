# Gateway Responsibility

## 역할
Gateway는 MSA 앞단의 외부 진입점이다.

- 클라이언트 요청을 최초로 받는다.
- 요청 채널을 판정한다.
- 인증 수단을 채널별로 선택한다.
- `ADMIN` 라우트의 최종 인가는 Authz에 위임한다.
- 외부 헤더를 제거하고 내부 헤더를 재주입한다.
- 성공 응답은 업스트림 응답을 그대로 전달한다.
- 실패 응답은 Gateway 표준 오류로 정규화한다.

## 책임 범위
- 외부 경로: `/v1/**`
- 라우트 판정: `PUBLIC`, `PROTECTED`, `ADMIN`, `INTERNAL`
- 인증 선검사: `PROTECTED`, `ADMIN`
- 관리자 인가 위임: `Authz`
- 내부 요청 보호: `X-Internal-Request-Secret`
- 추적 헤더 주입: `X-Request-Id`, `X-Correlation-Id`
- 내부 컨텍스트 주입: `X-User-Id`, `X-User-Status`, `X-Client-Type`, 내부 JWT `Authorization`

## 비책임 범위
- 비즈니스 도메인 로직
- 최종 인가 판단
- 서비스별 도메인 에러 코드
- 내부 서비스의 데이터 무결성

## 라우트 요약
- `PUBLIC`
  - 인증 선검사 없이 업스트림으로 전달한다.
- `PROTECTED`
  - Gateway 인증 선검사를 수행한다.
- `ADMIN`
  - Gateway 인증 선검사와 IP guard에 더해 Authz 판정을 통과해야 한다.
- `INTERNAL`
  - 내부 시크릿이 있어야 통과한다.
