# Security Contract

## 공통 원칙
1. Gateway는 외부 인증 선검사 수행 가능
2. 서비스는 최종 인증/인가를 자체 수행
3. 내부 API는 반드시 내부 JWT 검증

## User Service 내부 JWT 검증
- 검증 클레임: `iss`, `aud`, `sub`, `scope|scp`
- 요구 scope: `internal`

## /users/me
- Gateway 라우트 타입이 `PUBLIC`이어도,
- User Service는 `authenticated` + 활성 상태(`status=A`) 검증 수행

## CORS
- CORS는 Gateway에서 단일 처리
- 내부 서비스는 서비스 레벨 CORS 비활성 권장
