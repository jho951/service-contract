# Authz API Contract

## Base Paths
- Internal authorization: `/permissions/internal/admin/verify`
- Operations: `/health`, `/ready`

## Responsibility APIs
| 책임 API | Method | Path | Result |
| --- | --- | --- | --- |
| RBAC decision | `POST` | `/permissions/internal/admin/verify` | `200`, `403`, `400` |
| Audit emission | same request lifecycle | - | [Audit Contract](audit.md) 준수 |
| Health | `GET` | `/health` | `200` |
| Ready | `GET` | `/ready` | `200` or `DOWN` |

## Admin Authorization API

### `POST /permissions/internal/admin/verify`
| 항목 | 값 |
| --- | --- |
| 목적 | Gateway가 관리자 경로 요청을 위임할 때 사용하는 내부 판정 API |
| 필수 헤더 | `X-User-Id`, `X-User-Role`, `X-Session-Id`, `X-Original-Method`, `X-Original-Path` |
| 선택 헤더 | `X-Request-Id`, `X-Correlation-Id` |
| 응답 | `200` 허용, `403` 거부, `400` 입력 오류 |

### `GET /health`
| 항목 | 값 |
| --- | --- |
| 목적 | liveness 확인 |
| 응답 예시 | `status: UP` |

### `GET /ready`
| 항목 | 값 |
| --- | --- |
| 목적 | DB/Redis readiness 확인 |
| 응답 예시 | `status: UP|DOWN`, `components.db`, `components.redis` |

## Contract Notes
| 원칙 | 설명 |
| --- | --- |
| 실제 노출 API | 이 문서는 authz-service MVP의 실제 노출 API를 기록한다. |
| 판정 원칙 | 관리자 권한 판정은 deny-by-default이며 경로 기준으로 먼저 걸러진다. |
| readiness | `GET /ready`는 Redis 장애 시 `DOWN`을 반환할 수 있다. |
