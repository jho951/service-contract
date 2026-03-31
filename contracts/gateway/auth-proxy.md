# Gateway Auth Proxy

## 목적
Gateway가 요청 채널에 따라 인증 수단을 선택하고, 인증 결과를 내부 컨텍스트로 변환하는 흐름을 정리한다.

## 처리 순서
1. `Origin` / CORS 정책을 먼저 적용한다.
2. `OPTIONS` 요청은 `204 No Content`로 종료한다.
3. `GET /v1/health`, `GET /v1/ready`는 인증 없이 응답한다.
4. 라우트를 매칭한다.
5. `INTERNAL` / `ADMIN` / 로그인 경로 정책을 먼저 적용한다.
6. `PROTECTED` / `ADMIN` 라우트에서만 인증 선검사를 수행한다.
7. 요청 채널을 판정한다.
8. 채널에 맞는 인증 수단을 검증한다.
9. `ADMIN` 라우트는 인증 성공 후 authz-service의 `POST /permissions/internal/admin/verify`를 호출한다.
10. 인증 성공 시 내부 JWT와 사용자 컨텍스트를 재주입한다.
11. 업스트림으로 프록시하고 성공 응답은 passthrough 한다.

## 채널 판정
- 1순위: `X-Client-Type`
- 2순위: `Origin` / `Referer`
- 3순위: `User-Agent`
- 4순위: endpoint fallback

## 채널별 인증 수단
### `web`
- `ACCESS_TOKEN` 쿠키를 먼저 본다.
- 없으면 `sso_session` 쿠키로 auth-service 세션 검증을 수행한다.
- 브라우저 요청에서 `Authorization`이 함께 와도 Cookie 계열이 우선이다.

### `native` / `cli` / `api`
- `Authorization: Bearer <token>`을 먼저 본다.
- JWT 선검증, 서명 검증, `iss` / `aud` / `exp` 검증을 수행한다.
- 필요 시 auth-service 세션 검증과 L1/L2 캐시를 사용한다.

## 내부 정규화
- 성공하면 `X-User-Id`, `X-User-Status`, `X-Client-Type`를 재주입한다.
- 성공하면 내부 JWT를 `Authorization`으로 다시 넣는다.
- 외부 `Authorization`은 제거한다.
- `ADMIN` 라우트의 최종 허용 여부는 authz-service 판정 결과를 따른다.
- authz-service에는 `X-User-Id`, `X-User-Role`, `X-Session-Id`, `X-Original-Method`, `X-Original-Path`, `X-Request-Id`, `X-Correlation-Id`를 전달한다.
