# Common Audit Contract

감사 이벤트는 여러 서비스에서 발생하지만, 해석 기준은 공통이어야 한다. 이 문서는 서비스별 감사 이벤트를 설계할 때 따르는 공통 원칙을 정의한다.

## Scope
| Service | Representative events |
| --- | --- |
| Gateway | 인증 프록시 허용/거부, admin IP guard 차단, header normalization 실패 |
| Auth-service | login success/failure, SSO success/failure, refresh, logout, session revoke |
| Authz-service | authorization decision, role grant/revoke, policy change, delegation |
| User-service | profile change, visibility/privacy change, social link add/remove |
| Editor/Block | document/block create/update/delete/restore/share/publish |
| Redis | 운영자 수준 key 조작, cache invalidation |
| Monitoring | alert rule change, dashboard permission change, retention policy change |

## Required Fields
| Field | Meaning |
| --- | --- |
| `eventType` | 이벤트 이름 |
| `actorId` | 행위자 user id 또는 system actor |
| `targetType` | 대상 리소스 종류 |
| `targetId` | 대상 리소스 식별자 |
| `decision` | 허용/거부/성공/실패 같은 결과 |
| `reason` | 판단 또는 실패 사유 |
| `requestId` | 요청 단위 trace id |
| `correlationId` | 서비스 간 상관관계 id |
| `occurredAt` | 이벤트 발생 시각 |

## Rules
- 인증, 인가, 개인정보, 권한, 문서 변경 이벤트는 감사 대상이다.
- token, password, secret, raw credential은 감사 이벤트에 남기지 않는다.
- 서비스별 상세 이벤트 목록은 각 서비스의 `audit.md` 또는 README에서 관리한다.
- 공통 모듈 구현 세부는 [Module Ecosystem](../registry/module-ecosystem.md)의 `audit-log` 항목을 따른다.
- 저장소, 보존 기간, 조회 API가 별도 서비스로 분리되면 이 문서를 기준으로 서비스별 계약을 추가한다.

## Contract Placement
- 공통 감사 원칙: `shared/audit.md`
- 서비스별 감사 이벤트: `repositories/<repo>/audit.md` 또는 서비스 README
- 감사 모듈/라이브러리 의존성: `registry/module-ecosystem.md`
