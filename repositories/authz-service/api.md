# Authz API Contract

## Base Paths
- Internal authorization: `/permissions/internal/admin/verify`
- Operations: `/health`, `/ready`, `/error`
- Actuator: `/actuator/health`, `/actuator/prometheus`

## Responsibility APIs
| 책임 API | Method | Path | Result |
| --- | --- | --- | --- |
| RBAC decision | `POST` | `/permissions/internal/admin/verify` | `200`, `403`, `400` |
| Audit emission | same request lifecycle | - | [Audit Contract](audit.md) 준수 |
| Health | `GET` | `/health` | `200` |
| Ready | `GET` | `/ready` | `200` or `DOWN` |
| Actuator health | `GET` | `/actuator/health` | `200` |
| Prometheus metrics | `GET` | `/actuator/prometheus` | `200` |

## Admin Authorization API

### `POST /permissions/internal/admin/verify`
| 항목 | 값 |
| --- | --- |
| 목적 | Gateway가 관리자 경로 요청을 위임할 때 사용하는 내부 판정 API |
| 내부 인증 | `Authorization: Bearer <internal-service-jwt>` 또는 `X-Internal-Request-Secret` |
| 필수 헤더 | `X-User-Id`, `X-Original-Method`, `X-Original-Path` |
| 선택 헤더 | `X-Request-Id`, `X-Correlation-Id` |
| 응답 | `200` 허용, `403` 내부 caller proof 실패 또는 거부, `400` 입력 오류 |

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
| 실제 노출 API | 이 문서는 Authz MVP의 실제 노출 API를 기록한다. |
| 판정 원칙 | 관리자 권한 판정은 deny-by-default이며 `X-User-Id` 기준 role/permission 조회와 method/path 규칙으로 결정한다. |
| 신뢰하지 않는 입력 | `X-User-Role`은 필수 입력이 아니며 allow/deny 판정에 사용하지 않는다. |
| 내부 JWT 용도 | Authz가 받는 `internal-service-jwt`는 일반 보호 서비스용 `aud=internal-services` 토큰이 아니라, `aud=authz-service` caller proof 토큰이다. |
| readiness | `GET /ready`는 Redis 장애 시 `DOWN`을 반환할 수 있다. |
| OpenAPI | 기계 판독 계약은 [authz-service.upstream.v1.yaml](../../artifacts/openapi/authz-service.upstream.v1.yaml)에 둔다. |
