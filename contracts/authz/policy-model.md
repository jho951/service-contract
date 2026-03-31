# Policy Model

`Authz-server`의 권한 판단 기준을 정의한다.

## 기본 원칙
- 기본 거부(`default deny`)를 적용한다.
- 명시적 `DENY`는 `ALLOW`보다 우선한다.
- 권한은 `resource + action + condition + effect` 형태로 모델링한다.
- `role`은 입력값이고, 최종 판단은 정책 evaluator가 담당한다.

## 리소스 계층
| Level | Examples | Notes |
| --- | --- | --- |
| tenant | `tenant` | 멀티테넌시 경계 |
| workspace | `workspace` | 협업의 기본 경계 |
| project | `project` | 실무 작업 단위 |
| page | `page` | 실제 편집 단위 |
| block | `block` | v1에서는 page 권한 상속 우선 |
| comment | `comment` | 상호작용/토론 |
| share_link | `share_link` | 외부 공개/공유 경로 |
| membership | `membership` | 조직/팀/프로젝트 소속 |
| policy | `policy` | 정책 정의 자체 |
| delegation | `delegation` | 권한 위임 정의 |

## 액션 명명 규칙
- 형식은 `resource:verb`를 기본으로 한다.
- 예: `page:read`, `page:share`, `workspace:manage_members`, `comment:update:self`
- 고위험 작업은 별도 action으로 분리한다.

## 조건 속성
| Attribute | Meaning |
| --- | --- |
| `actor.id` | 요청 주체 식별자 |
| `actor.role` | 현재 역할 |
| `actor.workspaceId` | 워크스페이스 소속 |
| `actor.tenantId` | 테넌트 경계 |
| `resource.createdBy` | 리소스 소유자 |
| `resource.visibility` | `PRIVATE`, `TEAM`, `PUBLIC` |
| `resource.status` | `DRAFT`, `PUBLISHED`, `ARCHIVED` |
| `resource.locked` | 잠금 상태 |
| `delegation.validUntil` | 위임 만료 시각 |
| `mfaVerified` | step-up 완료 여부 |

## 정책 예시
```yaml
resource: page
action: update
effect: ALLOW
conditions:
  - actor.role in [OWNER, EDITOR]
  - actor.workspaceId == resource.workspaceId
  - resource.locked == false
```

```yaml
resource: comment
action: create
effect: ALLOW
conditions:
  - actor.role in [OWNER, EDITOR, REVIEWER]
  - resource.status != ARCHIVED
```

## 평가 우선순위
1. explicit `DENY`
2. resource-specific `ALLOW`
3. inherited `ALLOW`
4. default deny

## v1 / v2 경계
- v1은 관리자 RBAC와 기본 정책 판정 중심이다.
- v2는 policy engine, delegation, introspection, cache invalidation을 포함한다.
