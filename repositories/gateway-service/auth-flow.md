# Gateway Authentication Flow

## 목적
현재 `gateway-service` 구현 기준의 인증 흐름을 정리한다.

## 브라우저 인증
1. 사용자가 `auth-service`에 로그인한다.
2. `auth-service`는 상황에 따라 `ACCESS_TOKEN` 또는 `sso_session` 쿠키를 내려준다.
3. 브라우저는 `credentials: 'include'`로 Gateway를 호출한다.
4. Gateway는 `X-Client-Type`, `Origin`, `Referer`, `User-Agent`, endpoint 규칙으로 요청 채널을 판정한다.
5. `web` 채널로 판정되면 Gateway는 먼저 `ACCESS_TOKEN` 쿠키를 확인하고, 있으면 JWT 검증 경로로 처리한다.
6. `ACCESS_TOKEN`이 없으면 `sso_session` 쿠키로 auth-service 세션 검증을 수행한다.
7. 검증이 성공하면 Gateway는 내부용 `X-User-Id`, `X-User-Status`, `X-Client-Type`를 재주입하고, 내부용 `Authorization`도 다시 넣는다.
8. 내부 서비스는 Gateway가 재주입한 내부 컨텍스트만 신뢰하고 요청을 처리한다.

## 비브라우저 인증
1. 모바일, CLI, 서버 간 호출은 `Authorization: Bearer <token>`을 사용한다.
2. Gateway는 먼저 JWT 선검증과 서명/클레임 검증을 수행하고, 필요 시 auth-service 세션 검증과 캐시를 함께 사용한다.
3. 검증이 성공하면 Gateway는 내부용 `X-User-Id`, `X-User-Status`, `X-Client-Type`를 재주입하고, 내부용 `Authorization`도 다시 넣는다.
4. 내부 서비스는 Gateway가 재주입한 내부 컨텍스트만 신뢰하고 요청을 처리한다.

## 공통 원칙
- 외부에서 들어온 `X-User-Id`는 신뢰하지 않는다.
- 외부에서 들어온 `X-Client-Type`도 신원 식별 정보로 신뢰하지 않는다.
- 외부에서 들어온 `Authorization`은 그대로 downstream으로 전달하지 않고 제거한다.
- Gateway는 인증 성공 시 내부용 JWT를 `Authorization`으로 다시 주입한다.
- Gateway는 인증 결과를 내부 컨텍스트로 정규화한다.
- 모든 응답에는 `X-Request-Id`, `X-Correlation-Id`가 포함된다.

## 라우트 동작
- `PROTECTED` / `ADMIN` 라우트만 인증 선검사를 수행한다.
- `ADMIN` 라우트는 인증 성공 후 Authz의 `POST /permissions/internal/admin/verify`를 추가로 호출한다.
- `PUBLIC` 라우트는 인증 선검사 없이 업스트림으로 전달한다.
- `INTERNAL` 라우트는 `X-Internal-Request-Secret`이 필요한 별도 정책을 따른다.
- `ADMIN` 라우트는 IP guard를 추가로 통과해야 한다.
- 로그인 관련 경로는 client IP 기준 rate limit을 적용한다.
- `GET /v1/health` 와 `GET /v1/ready`는 인증 없이 응답한다.
- `OPTIONS` 요청은 `204 No Content`로 종료한다.
