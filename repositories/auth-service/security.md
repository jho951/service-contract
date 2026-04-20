# Auth Security Contract

Auth-service 보안 계약은 “외부 요청은 Gateway에서 정리하고, Auth-service는 인증 원천으로서 token/session을 검증한다”는 전제를 따른다.

## Trust Boundary
| 요청 출처                 | 신뢰 방식                             | 처리 원칙                               |
|-----------------------|-----------------------------------|-------------------------------------|
| External client       | 신뢰하지 않음                           | Gateway를 통해서만 진입한다.                 |
| Gateway               | 내부 JWT, routing policy, 재주입 header | Auth-service upstream API를 호출할 수 있다. |
| Internal service      | 내부 JWT 또는 internal secret         | `/internal/auth/*`만 필요한 범위에서 호출한다.  |
| User supplied headers | 신뢰하지 않음                           | 외부 `X-User-Id`, `X-User-Role`은 무시한다. |

Auth-service는 public `/v1` 또는 `/v2` auth prefix를 보안 경계로 삼지 않는다. public route versioning은 Gateway 책임이다.

## Token / Session Policy
### Browser
- Cookie 기반 인증을 우선한다.
- `ACCESS_TOKEN`, refresh token cookie, `sso_session` cookie를 사용할 수 있다.
- Browser 요청에 `Authorization` header가 같이 와도 Gateway에서는 cookie 계열을 우선한다.

### Native / CLI / API
- `Authorization: Bearer <token>`을 우선한다.
- JWT signature, issuer, audience, expiration 검증은 Gateway와 Auth-service 설정이 일치해야 한다.

### Refresh
- refresh token은 cookie 또는 header에서 추출한다.
- refresh 성공 시 access token과 refresh token을 새로 발급한다.
- refresh 실패는 invalid token, expired token, revoked session으로 분류한다.

## Internal Session Validation
`POST /auth/internal/session/validate`는 Gateway가 사용자 컨텍스트를 재구성하기 위한 API다.

Validation result:
- `authenticated`: 인증 성공 여부
- `userId`: 내부 사용자 식별자
- `status`: 사용자 상태
- `sessionId`: browser session id
- `role`: 호환용 인증 메타데이터이며 권한 판단 입력이 아님

Gateway는 이 결과를 바탕으로 내부 요청에 `X-User-Id`, `X-User-Status`, 내부 JWT를 재주입한다.
Gateway는 Auth-service 응답의 `role`을 `X-User-Role`로 재주입하지 않는다. 권한/역할 조회와 최종 판단은 authz-service가 `X-User-Id` 기준으로 수행한다.

## JWT / JWKS
- Auth-service는 JWT 발급자다.
- RSA 계열 서명을 쓰는 환경에서는 `/.well-known/jwks.json`이 공개키 source다.
- JWKS의 `kid`, `alg`, public key는 Gateway 검증 설정과 일치해야 한다.
- RSA가 아니거나 public key가 없으면 JWKS는 빈 `keys` 배열을 반환할 수 있다.

## SSO Security
- OAuth `state`는 ticket/session 교환 전에 검증되어야 한다.
- SSO ticket은 일회용이어야 한다.
- `admin` page SSO는 IP guard 같은 추가 정책을 적용할 수 있다.
- redirect URI는 등록된 값과 일치해야 한다.

## Audit / Policy
- password login success/failure, SSO success/failure, refresh, logout, internal account change는 audit 대상이다.
- 로그인 실패 횟수와 계정 잠금은 Auth-service 정책에 포함된다.
- 권한 판단 이벤트는 authz-service audit 계약과 분리한다.
