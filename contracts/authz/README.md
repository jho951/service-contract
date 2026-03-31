# Authz Contract

`Authz` 서비스 계약 허브다. 디렉터리 경로는 기존 호환성을 위해 `contracts/authz`를 유지한다.

## 책임
| 책임 | 범위 |
| --- | --- |
| 관리자 경로 인가 | `/admin/**`, `/v1/admin/**` 접근 허용/거부 판정 |
| RBAC 판정 | `ADMIN`, `MANAGER`, `MEMBER` 기반 권한 매핑 |
| 감사 추적 | `requestId`, `correlationId`, `decision`, `reason` 기록 |
| 운영 준비 상태 | DB/Redis ready 체크 제공 |

## 문서
- [API Contract](api.md)
- [v2 Design](v2.md)
- [Policy Model](policy-model.md)
- [Delegation Contract](delegation.md)
- [Versioning Contract](versioning.md)
- [Introspection Contract](introspection.md)
- [Cache Contract](cache.md)
- [External Boundaries](external-boundaries.md)
- [RBAC Contract](rbac.md)
- [Audit Contract](audit.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Error Contract](errors.md)
- [Authz Service OpenAPI](../openapi/authz-service.v1.yaml)
- [Authz Service OpenAPI v2](../openapi/authz-service.v2.yaml)

## API
| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/permissions/internal/admin/verify` | 관리자 경로 RBAC 판정 |
| `GET` | `/health` | liveness 확인 |
| `GET` | `/ready` | readiness 확인 |

## 계약 원칙
| 원칙 | 설명 |
| --- | --- |
| 위임 대상 | Gateway는 `/admin/**`, `/v1/admin/**`를 authz-service로 위임한다. |
| 입력 헤더 | `X-User-Id`, `X-User-Role`, `X-Session-Id`, `X-Original-Method`, `X-Original-Path` |
| 추적 헤더 | `X-Request-Id`, `X-Correlation-Id` |
| 판정 기준 | DB RBAC 매핑과 요청 메서드/경로 규칙 |
| 신뢰 경계 | 외부 주입 trusted header는 Gateway 재주입 값만 신뢰한다. |
| 공개 범위 | 권한을 프로필에 공개할지 여부는 user-service privacy/visibility 정책이 소유한다. |
