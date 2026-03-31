# CONTRACT_SYNC.md

## Repository
- Repo: `https://github.com/jho951/Explain-page`
- Branch: `main`
- Role: `frontend-consumer`

## Contract Source
- Contract Repo: `https://github.com/jho951/contract`
- Contract Commit SHA: `<contract-sha>`
- Latest Sync Date: `<YYYY-MM-DD>`

## Referenced Contract Docs
- `contracts/common/routing.md`
- `contracts/common/headers.md`
- `contracts/common/security.md`
- `contracts/auth/README.md`
- `contracts/user/README.md`
- `contracts/gateway/errors.md`
- `contracts/common/env.md`
- `contracts/openapi/gateway-edge.v1.yaml`
- `contracts/openapi/user-service.v1.yaml`
- `contracts/openapi/auth-service.v1.yaml`
- `contracts/openapi/block-service.v1.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
  - `auth`
  - `user`
  - `errors`
  - `env`
  - `openapi`
- Affected Flows:
  - `로그인/세션 갱신` -> `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`
  - `사용자 컨텍스트/소셜 연결` -> `GET /v1/users/me`, `POST /v1/internal/users/find-or-create-and-link-social`

## Frontend Notes
- 게이트웨이를 통해 노출되는 경로와 직접 호출하는 내부 경로를 구분한다.
- 로그인/리다이렉트 흐름은 `contracts/openapi/auth-service.v1.yaml`과 맞춘다.
- 사용자 상태, 소셜 링크, 현재 사용자 조회는 `contracts/openapi/user-service.v1.yaml`과 맞춘다.
- 인증 실패 시의 리다이렉트/에러 화면 처리도 계약 변경 영향 범위에 포함한다.
- mock data, fallback UI, feature-flag가 있으면 이 파일에 같이 기록한다.
- 계약 변경이 페이지 상호작용에 영향을 주면 같은 PR에서 갱신한다.

## Validation
- Commands:
  - `pnpm test`
  - `pnpm lint`
  - `pnpm build`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<routing, headers, ...>` | `<short note>` |
