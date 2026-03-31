# CONTRACT_SYNC.md

## Repository
- Repo: `https://github.com/jho951/Editor-page`
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
- `contracts/gateway/errors.md`
- `contracts/common/env.md`
- `contracts/editor/README.md`
- `contracts/editor/schema-v1.md`
- `contracts/editor/rules-v1.md`
- `contracts/editor/api.md`
- `contracts/editor/db-migration.md`
- `contracts/editor/authz.md`
- `contracts/editor/operations.md`
- `contracts/editor/errors.md`
- `contracts/editor/security.md`
- `contracts/editor/ops.md`
- `contracts/editor/cache.md`
- `contracts/openapi/editor.v1.yaml`
- `contracts/openapi/gateway-edge.v1.yaml`
- `contracts/openapi/user-service.v1.yaml`
- `contracts/openapi/auth-service.v1.yaml`
- `contracts/openapi/block-service.v1.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
  - `errors`
  - `env`
  - `editor-v1`
  - `editor-authz`
  - `editor-operations`
  - `editor-errors`
  - `editor-security`
  - `editor-ops`
  - `editor-cache`
  - `openapi`
- Affected Flows:
  - `Document / Block 조회`
  - `Document 이동/정렬/복사/삭제`
  - `Block content 편집`

## Frontend Notes
- Gateway 노출 경로는 `/v1/**` 기준으로만 사용한다.
- 현재 편집 화면은 `contracts/editor/api.md` 및 `contracts/openapi/editor.v1.yaml`과 맞춘다.
- 문서 목록, 상세, 블록 조회는 editor v1 API와 block-service OpenAPI를 함께 본다.
- 인증이 필요한 화면은 `Authorization: Bearer <token>` 전송을 전제로 한다.
- 휴지통, 복구, 이동, 관리자 블록 조작은 권한에 따라 UI 노출을 분기한다.
- 미래 Node 전환은 별도 계약 문서(v2)를 참고한다.
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
