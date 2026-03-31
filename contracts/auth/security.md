# Auth Security Contract

## Trust Boundary
- 외부 클라이언트는 Gateway를 통해 auth-service에 접근하는 것을 기본으로 한다.
- 내부 엔드포인트는 Gateway 또는 내부 네트워크에서만 사용한다.
- 외부에서 주입된 `X-User-Id`는 신뢰하지 않는다.

## Token Policy
- 브라우저 경로는 쿠키 기반 세션을 우선한다.
- 비브라우저 경로는 Bearer token을 우선한다.
- auth-service는 토큰 발급 원천이며 Gateway는 이를 내부 사용자 컨텍스트로 정규화한다.

## Internal Session Validation
- `POST /auth/internal/session/validate` 는 내부 세션 검증 전용이다.
- 응답은 authenticated 여부와 사용자 식별 정보를 포함한다.
- Gateway는 이 응답을 내부 컨텍스트 재구성에 사용한다.

## JWT and JWKS
- auth-service는 JWT 발급자 역할을 한다.
- 서비스 간 공개키 검증은 JWKS 또는 동등한 공개키 배포 체계를 통해 처리한다.
- 서명 알고리즘과 키 운영 정책은 배포 환경에서 일관되어야 한다.
- RSA 모드에서는 `/.well-known/jwks.json` 이 공개키 소스가 된다.

## Audit and Policy
- 로그인 성공/실패는 감사 로그에 남겨야 한다.
- 계정 잠금, 실패 횟수 제한, 세션 무효화는 보안 정책의 일부다.
