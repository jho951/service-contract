# Registry

`registry`는 이 contract repo가 관리하는 repository 목록, adoption 상태, 운영 절차, 배포 토폴로지를 담는다.
개별 repository 계약 본문은 `repositories/<repo>`에 두고, registry는 전체 지도를 관리한다.

## 구조
| 문서 | 역할 |
| --- | --- |
| [repositories.yml](repositories.yml) | machine-readable repository registry |
| [adoption-matrix.md](adoption-matrix.md) | repository별 계약 반영 상태 |
| [service-ownership.md](service-ownership.md) | repo 계층 분류와 소유권 |
| [deployment-topology.md](deployment-topology.md) | EC2 기준 배포, network, security group, 운영 체크리스트 |
| [module-ecosystem.md](module-ecosystem.md) | 공통 모듈과 외부 모듈 책임 |
| [adoption-playbook.md](adoption-playbook.md) | 서비스 레포에 contract 기준을 도입하는 절차 |
| [lifecycle.md](lifecycle.md) | 계약 변경 생명주기 |
| [ai-agent-playbook.md](ai-agent-playbook.md) | AI agent가 계약 기준으로 서비스 수정하는 절차 |
| [automation.md](automation.md) | contract lock 검증과 자동화 방향 |
| [troubleshooting.md](troubleshooting.md) | 장애 분류와 복구 가이드 |

## 원칙
- repository별 계약은 `repositories/<repo>`에 둔다.
- 공통 규칙은 `shared`에 둔다.
- OpenAPI와 JSON Schema는 `artifacts`에 둔다.
- 서비스 레포에 복사할 문서는 `templates`에 둔다.
