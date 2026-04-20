# Repositories

`repositories`는 실제 GitHub repository가 소비하는 계약 문서를 repo 단위로 담는다.
디렉토리 이름은 contract 영역명이 아니라 repository 이름을 kebab-case로 맞춘다.

## Repository Contracts
| Directory | GitHub repository | Branch |
| --- | --- | --- |
| [gateway-service](gateway-service/README.md) | https://github.com/jho951/gateway-service | `main` |
| [auth-service](auth-service/README.md) | https://github.com/jho951/auth-service | `main` |
| [authz-service](authz-service/README.md) | https://github.com/jho951/authz-service | `main` |
| [user-service](user-service/README.md) | https://github.com/jho951/user-service | `main` |
| [editor-service](editor-service/README.md) | https://github.com/jho951/editor-service | `dev` |
| [redis-service](redis-service/README.md) | https://github.com/jho951/redis-service | `main` |
| [monitoring-service](monitoring-service/README.md) | https://github.com/jho951/monitoring-service | `main` |

## Rules
- 공통 규칙은 여기로 복제하지 않고 [shared](../shared/README.md)를 링크한다.
- repository별 README는 `Source` 표에 GitHub repo, branch, `contract.lock.yml`을 명시한다.
- OpenAPI와 JSON Schema는 [artifacts](../artifacts/README.md)에 둔다.
