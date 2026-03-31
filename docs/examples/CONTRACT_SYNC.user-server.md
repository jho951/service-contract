# CONTRACT_SYNC.md

## Repository
- Repo: `https://github.com/jho951/User-server`
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
- `contracts/user/README.md`
- `contracts/user/api.md`
- `contracts/user/security.md`
- `contracts/user/ops.md`
- `contracts/user/errors.md`
- `contracts/user/visibility.md`
- `contracts/openapi/user-service.v1.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
  - `user`
  - `user-visibility`
  - `user-ops`
  - `user-errors`
  - `openapi`
- Affected Endpoints or Flows:
  - `POST /users/signup`
  - `GET /users/me`
  - `POST /internal/users`
  - `POST /internal/users/social`
  - `POST /internal/users/ensure-social`
  - `POST /internal/users/find-or-create-and-link-social`
  - `PUT /internal/users/{userId}/status`
  - `GET /internal/users/{userId}`
  - `GET /internal/users/by-email`
  - `GET /internal/users/by-social`

## Service Notes
- 공개 API는 Gateway 경유를 기본으로 한다.
- 내부 사용자 식별은 `X-User-Id`와 내부 JWT를 기준으로 한다.
- 소셜 연동과 상태 변경은 내부 계약에 따라 멱등성과 정합성을 유지한다.
- 프로필 가시성/개인정보 공개 정책은 user-service의 별도 계약으로 관리한다.

## Validation
- Commands:
  - `<test-or-smoke-command-1>`
  - `<test-or-smoke-command-2>`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<routing, headers, ...>` | `<short note>` |
