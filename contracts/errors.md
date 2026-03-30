# Error Contract

## Gateway 표준화 코드
- `502`: `UPSTREAM_FAILURE`
- `504`: `UPSTREAM_TIMEOUT`

## 원칙
1. Gateway는 업스트림 실패를 502/504로 표준화
2. Downstream은 자체 도메인 에러 코드를 유지
3. 로그 상관관계는 `X-Request-Id`로 추적

## 모니터링
- Gateway: 502/504 비율, 업스트림별 실패율
- Service: 처리시간 p95/p99, 내부 예외율
