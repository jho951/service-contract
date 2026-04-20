# Authz Versioning Contract

이 문서는 권한 변경과 토큰 불일치 처리를 정의한다.

## 버전 종류
| Version | Meaning |
| --- | --- |
| `authz_version` | 사용자 권한 스냅샷의 버전 |
| `policy_version` | 정책 정의 버전 |
| `membership_version` | 조직/프로젝트 소속 버전 |
| `delegation_version` | 위임 상태 버전 |

## 기본 원칙
- 토큰에는 최소 identity와 coarse scope만 넣는다.
- 민감한 권한은 Authz 서버의 현재 상태를 다시 확인한다.
- 중요한 API는 버전 불일치 시 재평가한다.

## 버전 증가 트리거
- role grant/revoke
- policy update/delete
- membership change
- delegation change
- tenant suspension

## 권장 정책
| API class | Strategy |
| --- | --- |
| low-risk read | JWT + short cache |
| medium-risk edit/comment | JWT + authz cache |
| high-risk share/delete/admin | current authz version recheck |

## 불일치 처리
- `authz_version` 불일치가 감지되면 cached decision을 무효화한다.
- `policy_version` 불일치는 policy evaluator 재실행을 의미한다.
- `membership_version` 불일치는 workspace/project scope 재검사를 의미한다.
