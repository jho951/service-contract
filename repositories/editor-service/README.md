# Editor Contract

현재 `editor-service`의 `documents-api` 구현 기준으로 v1 문서/블록 계약을 정의하고, v2 확장 축은 shared operation core + separated persistence로 둔다.

## Source
| 항목            | 값                                        |
|---------------|------------------------------------------|
| Repo          | https://github.com/jho951/editor-service |
| Branch        | `main`                                   |
| Contract Lock | `contract.lock.yml`                      |

## 현재 v1
- [Schema v1](schema-v1.md)
- [Rules v1](rules-v1.md)
- [API v1](api.md)
- [Persistence & Migration](db-migration.md)
- [Authorization & Ownership](authz.md)
- [Operations Semantics](operations.md)
- [Error Contract](errors.md)
- [Security Contract](security.md)
- [Operating Contract](ops.md)
- [Cache Contract](cache.md)
- [Common Audit Contract](../../shared/audit.md)

## 현재 확장
- [V2 Extension](v2-extension.md)

## 미래 Node v2
- [Schema v2](schema-v2.md)
- [Rules v2](rules-v2.md)
- [API v2](api-v2.md)
- [v2 OpenAPI](../../artifacts/openapi/editor.v2.yaml)

## 범위
- v1 활성 범위는 `Document`와 `Block`이다.
- `Workspace`는 backup 전용이며 v1 활성 API에 노출하지 않는다.
- 외부 노출 경로는 Gateway 기준 `/v1/documents/**`, `/v1/admin/**`이다.
- 서비스 내부 경로는 `/documents/**`, `/admin/**`이다.
- v1 응답은 `GlobalResponse` envelope을 사용한다.
- `Document`는 `visibility`, `trash`, `restore`, `move`, `transactions`를 포함한다.
- `Block`은 `TEXT`만 지원하며, 현재 저장/이동/삭제는 transaction 기반이다.
- `Block restore`는 현재 v1에 없다.
- main 확장 목표는 shared operation core와 separated persistence를 동시에 유지하는 것이다.
- `parentId` / `sortKey` 기반 트리 구조와 rich text payload 규칙을 유지한다.

## 원칙
1. v1은 현재 운영 기준이다.
2. main 확장은 shared operation core + separated persistence 설계안이다.
3. `Workspace`는 v1에서 backup 전용이며, 재설계 전까지 활성 API에 노출하지 않는다.
4. Node 영속 통합은 별도 미래 Node v2 문서로만 유지한다.
5. 문서/블록의 현재 계약은 v1 문서를 따른다.
6. 권한/보안/운영/캐시/에러 규칙은 현재 구현과 함께 맞춘다.
7. backup Workspace 관련 코드는 `backup/workspace/` 아래에서만 보관한다.
8. capability truth는 `authz-service`, 공개 범위는 `user-service`, 최종 실행은 `Editor`가 강제한다.
