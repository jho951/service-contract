# Authz External Boundaries

이 문서는 `Gateway`, `Auth`, `Authz`, `User`, `Editor`의 책임 경계를 고정한다.

## 책임 분리
| Service | Responsibility |
| --- | --- |
| Gateway | 요청 정규화, trusted header 재주입, coarse route protection |
| auth-service | 인증, 세션, JWT 발급, identity proof |
| authz-service | capability truth, policy evaluation, delegation, introspection |
| user-service | 사용자 마스터 데이터, profile visibility/privacy |
| Editor | 실제 도메인 행위의 최종 허용/거부 |

## 규칙
- Auth는 `누구냐`를 판정한다.
- Authz는 `무엇을 할 수 있냐`를 판정한다.
- User는 `그 사실을 공개할 거냐`를 판정한다.
- Editor는 `그 행위를 실제로 처리할 거냐`를 판정한다.
- Gateway는 이 책임들을 대체하지 않는다.
- 정책 판단 시에는 `role`, `condition`, `token scope`, `cache invalidation`, `final enforcement`를 함께 확인한다.
- 정책 평가는 `plugin-policy-engine` 런타임이 수행하고, 계약 기준은 `policy-model.md`를 따른다.
- 고위험 작업일수록 `Gateway`보다는 `Authz`와 `Editor`의 재검증 비중을 높인다.

## 고위험 경로
- share / publish
- role grant / revoke
- visibility change
- delete / restore
- admin access

이 경로들은 로컬 JWT 검증만으로 종결하지 않고, 현재 권한 상태와 정책 버전을 재확인해야 한다.
