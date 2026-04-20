# Templates

이 디렉토리는 서비스 레포에 복사하거나 PR 본문에 붙일 수 있는 템플릿과 예시 문서를 담는다.

## Templates
| File | Purpose |
| --- | --- |
| [contract-lock-template.yml](contract-lock-template.yml) | 모든 서비스/프론트 레포용 `contract.lock.yml` 기본 템플릿 |
| [agent-task-template.md](agent-task-template.md) | AI agent 작업 지시 템플릿 |
| [readme-contract-source-backend.md](readme-contract-source-backend.md) | 백엔드 README에 넣을 contract source 섹션 |
| [readme-contract-source-monitoring.md](readme-contract-source-monitoring.md) | monitoring-service README에 넣을 contract source 섹션 |
| [readme-contract-source-frontend.md](readme-contract-source-frontend.md) | 프론트엔드 README에 넣을 contract source 섹션 |
| [github-actions-contract-check.yml](github-actions-contract-check.yml) | 공통 contract check, test/build, image, deploy gate workflow |

## Notes
- 새 서비스 레포에는 `contract.lock.yml`을 우선 배치한다.
- `consumes`에는 해당 서비스가 직접 참조하는 문서와 OpenAPI만 남긴다.
