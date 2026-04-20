# Authz Policy Engine Contract

`plugin-policy-engine`는 `authz-service`가 현재 사용하는 정책 평가 런타임이다.  
이 문서는 정책 모델을 실제 판정 로직에 연결할 때 지켜야 할 경계를 고정한다.

## 책임
| 책임 | 범위 |
| --- | --- |
| 정책 평가 | `resource + action + condition + effect` 판정 |
| 판정 결과 | `ALLOW` / `DENY` 및 사유, 버전 정보를 반환 |
| 현재 상태 확인 | `authz_version`, `policy_version`, `delegation_version` 불일치 확인 |
| 실행 런타임 | Maven Central에 publish된 `plugin-policy-engine` 모듈 |

## 입력
| 항목 | 설명 |
| --- | --- |
| subject | 사용자/서비스 식별자 |
| resource | 대상 리소스 |
| action | 수행 행위 |
| condition | 문맥/부가 조건 |
| role | 현재 role snapshot |
| scopes | 현재 scope snapshot |
| versions | `authz_version`, `policy_version`, `membership_version`, `delegation_version` |

## 출력
| 항목 | 설명 |
| --- | --- |
| decision | `ALLOW` / `DENY` |
| reason | 판정 사유 코드 |
| policyVersion | 평가에 사용한 정책 버전 |
| authzVersion | 현재 권한 버전 |
| matchedPolicy | 선택적으로 매칭된 정책 식별자 |

## 동작 원칙
- `policy-model.md`의 문법과 우선순위를 그대로 따른다.
- `default deny`를 기본값으로 한다.
- `DENY`는 `ALLOW`보다 우선한다.
- 토큰에 이미 들어 있는 claim은 보조 입력일 뿐, 최종 판정은 evaluator가 수행한다.
- 고위험 권한은 evaluator 결과만으로 끝내지 않고, `introspection` 또는 최신 상태 확인을 붙일 수 있다.

## 경계
- 정책 authoring/배포/승인 워크플로우는 이 문서의 범위가 아니다.
- policy definition 관리가 필요해지면 `policy-config` 모듈과 별도 계약을 둔다.
- `authz-service`는 정책 진실과 평가 결과를 소유하고, `plugin-policy-engine`은 런타임 evaluator로만 사용한다.
