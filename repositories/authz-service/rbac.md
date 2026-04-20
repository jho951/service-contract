# Authz RBAC Contract

## 입력 컨텍스트
| 헤더 | 역할 |
| --- | --- |
| `X-User-Id` | 사용자 식별 |
| `X-Session-Id` | 세션 식별 보조값 |
| `X-Original-Method` | 원본 메서드 |
| `X-Original-Path` | 원본 경로 |
| `X-Request-Id` | 추적용 |
| `X-Correlation-Id` | 추적용 |

## 판정 규칙
| 규칙 | 설명 |
| --- | --- |
| 정책 기준 | `X-User-Id`로 조회한 role/permission과 DB에 저장된 path/method 정책을 기준으로 한다. |
| 신뢰하지 않는 입력 | `X-User-Role`은 판정 입력으로 사용하지 않는다. |
| 기본 정책 | 관리자 경로는 deny-by-default다. |
| 기본 거부 | `MANAGER`, `MEMBER`는 명시적 허용 정책이 없으면 거부한다. |

## 정책 범위
| 대상 경로 |
| --- |
| `/admin/**` |
| `/v1/admin/**` |
| `/admin/manage/**` |
| `/v1/admin/manage/**` |

## 계약 원칙
| 원칙 | 설명 |
| --- | --- |
| 외부화 | RBAC 결과는 `POST /permissions/internal/admin/verify`의 `200/403`으로 외부화한다. |
| 비노출 | 내부 정책 키나 저장 테이블 이름은 외부 계약에 포함하지 않는다. |
| 감사 연동 | 정책 변경은 감사 이벤트와 함께 추적한다. |
