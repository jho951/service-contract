# Policy Model

`authz-service`의 권한 판단 기준을 정의한다.

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

## 판단 체크리스트
정책이나 API를 추가할 때 아래 질문으로 먼저 분해한다.

1. 이 권한은 `role`만으로 충분한가, 아니면 `condition`이 필요한가?
2. 이 기능은 문서 협업 편의 기능인가, 아니면 보안상 중요한 권한인가?
3. 이 권한은 토큰 안에 넣어도 되는 수준인가, 아니면 항상 현재 상태 조회가 필요한가?
4. 이 변경이 일어나면 어떤 캐시를 무효화해야 하는가?
5. 이 판단은 `Gateway`, `Authz`, `Editor` 중 어디가 최종 책임을 져야 하는가?

## 해석 규칙
- `role`만으로 충분하지 않으면 `condition`을 반드시 추가한다.
- 보안상 중요한 권한이면 토큰만 믿지 않고 `introspection` 또는 현재 상태 재평가를 요구한다.
- 캐시 무효화가 명확하지 않으면 TTL만으로 운영하지 않는다.
- 최종 허용/거부가 도메인 실행과 결합되면 `Editor`가 최종 집행자가 된다.

## v1 / v2 경계
- v1은 관리자 RBAC와 기본 정책 판정 중심이다.
- v2는 policy engine, delegation, introspection, cache invalidation을 포함한다.

## Runtime Binding
- 현재 authz-service의 정책 평가 런타임은 Maven Central에 publish된 `plugin-policy-engine`을 사용한다.
- `policy-model.md`는 evaluator 구현체가 아니라, evaluator가 따라야 하는 계약 기준이다.
- evaluator가 바뀌어도 리소스 계층, 액션 네이밍, 조건 속성, 우선순위는 이 문서를 기준으로 유지한다.
