# Security Contract

## 공통 원칙
1. Gateway는 외부 인증 선검사 수행 가능
2. 서비스는 최종 인증/인가를 자체 수행
3. 내부 API는 반드시 내부 JWT 검증

## 인증 채널 정책
- 상세 규약은 [Authentication Channel Policy](auth-channel-policy.md)를 따른다.
- Gateway는 먼저 라우트 성격을 판정한 뒤, 요청 채널을 결정하고 하이브리드 인증 수단을 선택한다.
- 기본 우선순위는 `web=Cookie`, `native|cli|api=Bearer`다.
- 둘 다 존재하면 판정 결과에 따라 선택한다.
- 최종 인증 성공 후 Gateway는 내부 `X-User-Id`로 정규화한다.
- 외부에서 들어온 `X-User-Id`는 신뢰하지 않는다.
- 외부에서 들어온 `Authorization`은 Gateway가 제거하고, 성공 시 내부 JWT만 다시 넣는다.
- 내부 서비스는 Cookie나 외부 Bearer를 직접 신뢰하지 않고, Gateway가 재주입한 `Authorization`, `X-User-Id`, `X-User-Status`, `X-Client-Type`를 신뢰한다.

## User Service 내부 JWT 검증
- 검증 클레임: `iss`, `aud`, `sub`, `scope|scp`
- 요구 scope: `internal`

## /users/me
- Gateway 라우트 타입이 `PUBLIC`이어도,
- User Service는 `authenticated` + 활성 상태(`status=A`) 검증 수행
- 브라우저 호출은 Cookie 기반 세션을 우선으로 한다.
- 비브라우저 호출은 Bearer 토큰을 우선으로 한다.

## CORS
- CORS는 Gateway에서 단일 처리
- 내부 서비스는 서비스 레벨 CORS 비활성 권장
