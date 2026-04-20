# Authz Contract

`Authz` 계약 허브다. 공개 서비스명은 `authz-service`로 통일하고, 디렉터리 경로는 기존 호환성을 위해 `repositories/authz-service`를 유지한다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/authz-service |
| Branch | `main` |
| Contract Lock | `contract.lock.yml` |

## 책임
| 책임 | 범위 |
| --- | --- |
| 관리자 경로 인가 | `/admin/**`, `/v1/admin/**` 접근 허용/거부 판정 |
| RBAC/permission 판정 | `X-User-Id` 기준 role/permission 조회와 method/path/resource/action 기반 허용/거부 |
| 감사 추적 | `requestId`, `correlationId`, `decision`, `reason` 기록 |
| 운영 준비 상태 | DB/Redis ready 체크 제공 |
| 감사 이벤트 발행 | `audit-log`로 정책/역할/위임/판정 이벤트를 발행 |
| 정책 엔진 | `plugin-policy-engine`로 resource/action/condition/effect 판정을 수행 |

## 문서
- [API Contract](api.md)
- [v2 Design](v2.md)
- [Policy Model](policy-model.md)
- [Policy Engine Contract](policy-engine.md)
- [Delegation Contract](delegation.md)
- [Versioning Contract](versioning.md)
- [Introspection Contract](introspection.md)
- [Cache Contract](cache.md)
- [External Boundaries](external-boundaries.md)
- [RBAC Contract](rbac.md)
- [Audit Contract](audit.md)
- [Common Audit Contract](../../shared/audit.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Error Contract](errors.md)
- [Authz OpenAPI](../../artifacts/openapi/authz-service.v1.yaml)
- [Authz OpenAPI v2](../../artifacts/openapi/authz-service.v2.yaml)

## API
| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/permissions/internal/admin/verify` | 관리자 경로 RBAC 판정 |
| `GET` | `/health` | liveness 확인 |
| `GET` | `/ready` | readiness 확인 |

## 계약 원칙
| 원칙 | 설명 |
| --- | --- |
| 위임 대상 | Gateway는 `/admin/**`, `/v1/admin/**`를 Authz로 위임한다. |
| 입력 헤더 | `X-User-Id`, `X-Session-Id`, `X-Original-Method`, `X-Original-Path` |
| 추적 헤더 | `X-Request-Id`, `X-Correlation-Id` |
| 판정 기준 | `X-User-Id`로 조회한 role/permission과 요청 메서드/경로/resource/action 규칙 |
| 신뢰 경계 | 외부 주입 trusted header는 Gateway 재주입 값만 신뢰한다. |
| 공개 범위 | 권한을 프로필에 공개할지 여부는 user-service privacy/visibility 정책이 소유한다. |
| role header | `X-User-Role`은 신뢰하지 않고 판정 입력으로 사용하지 않는다. |
| admin IP guard | authz-service는 IP guard를 소유하지 않는다. 관리자/internal route IP guard는 Gateway 책임이다. |
| 감사 sink | Authz는 감사 이벤트를 `audit-log` 모듈에 발행하고, 저장/조회 정책은 audit-log 계약을 따른다. |
