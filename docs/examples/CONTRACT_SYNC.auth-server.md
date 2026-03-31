# CONTRACT_SYNC.md

## Repository
- Repo: `https://github.com/jho951/Auth-server`
- Branch: `main`
- Role: `backend-service`

## Contract Source
- Contract Repo: `https://github.com/jho951/contract`
- Contract Commit SHA: `<contract-sha>`
- Latest Sync Date: `<YYYY-MM-DD>`

## Referenced Contract Docs
- `contracts/common/routing.md`
- `contracts/common/headers.md`
- `contracts/common/security.md`
- `contracts/auth/README.md`
- `contracts/auth/api.md`
- `contracts/auth/v2.md`
- `contracts/auth/security.md`
- `contracts/auth/ops.md`
- `contracts/auth/errors.md`
- `contracts/openapi/auth-service.v1.yaml`
- `contracts/openapi/auth-service.v2.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
  - `auth`
  - `auth-v2`
  - `auth-ops`
  - `auth-errors`
  - `openapi`
- Affected Endpoints or Flows:
  - `POST /auth/login`
  - `POST /auth/refresh`
  - `POST /auth/logout`
  - `GET /auth/sso/start`
  - `GET /auth/oauth2/authorize/{provider}`
  - `POST /auth/exchange`
  - `POST /auth/internal/session/validate`
  - `GET /auth/me`
  - `GET /`
  - `GET /v1`
  - `GET /.well-known/jwks.json`
  - `POST /v2/auth/login`
  - `POST /v2/auth/mfa/challenge`
  - `POST /v2/auth/mfa/verify`
  - `GET /v2/auth/sso/start/{provider}`
  - `GET /v2/auth/oauth2/authorize/{provider}`
  - `GET /v2/auth/sessions`
  - `DELETE /v2/auth/sessions/{sessionId}`
  - `POST /v2/auth/logout-all`
  - `POST /v2/auth/internal/session/introspect`

## Service Notes
- Gateway 경유 인증 흐름을 기본으로 맞춘다.
- 쿠키 기반 브라우저 인증과 Bearer 기반 비브라우저 인증을 함께 유지한다.
- 내부 엔드포인트는 내부 JWT 또는 Gateway 재주입 컨텍스트만 신뢰한다.
- v2는 MFA, step-up, SSO provider 확장, session lifecycle, account policy 확장, internal management API 확장을 포함한다.

## v2 Notes
- MFA는 `MfaFactor` 기반으로 TOTP, WebAuthn, 복구 코드를 모두 수용한다.
- SSO provider는 GitHub, Google, Apple, Kakao, SAML, OIDC를 registry 기반으로 분리한다.
- 세션 수명주기는 device/session inventory, revoke-by-device, logout-all, introspection을 포함한다.
- 계정 정책은 `active`, `locked`, `suspended` 전이를 명시하고 비밀번호 만료와 위험 기반 잠금을 포함한다.
- 내부 관리 API는 비밀번호 초기화, 잠금/해제, MFA 등록/폐기, 소셜 연동 해제, 계정 동기화를 포함한다.

## Validation
- Commands:
  - `./gradlew bootRun`
  - `curl -i http://localhost:8081/`
  - `curl -i http://localhost:8081/.well-known/jwks.json`
  - `curl -i -X POST http://localhost:8081/v2/auth/login -H 'Content-Type: application/json' -d '{"username":"user@example.com","password":"password1234"}'`
  - `curl -i -X POST http://localhost:8081/v2/auth/mfa/verify -H 'Content-Type: application/json' -d '{"challengeId":"mfa-challenge-123","code":"123456"}'`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<routing, headers, ...>` | `<short note>` |
