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
| [editor-service](editor-service/README.md) | https://github.com/jho951/editor-service | `main` |
| [editor-page](editor-page/README.md) | https://github.com/jho951/Editor-page | `master` |
| [explain-page](explain-page/README.md) | https://github.com/jho951/Explain-page | `main` |
| [redis-service](redis-service/README.md) | https://github.com/jho951/redis-service | `main` |
| [monitoring-service](monitoring-service/README.md) | https://github.com/jho951/monitoring-service | `main` |

## Current Docker Baseline
| Repo | Current compose service name | Port | Health/Ready |
| --- | --- | --- | --- |
| `gateway-service` | service key `gateway-service`, shared alias `gateway` | `8080` | runtime `/health`, `/ready`; public contract `/v1/health`, `/v1/ready` |
| `auth-service` | `auth-service` | container `8081`, local JVM `8081` | `/health`, `/ready` |
| `authz-service` | `authz-service` | `8084` | `/health`, `/ready` |
| `user-service` | `user-service` | `8082` | `/health`, `/ready` |
| `editor-service` | service key `editor-service`, DB host `editor-mysql` | `8083` | `/actuator/health`, `/actuator/health/readiness` |
| `redis-service` | `redis-server` with shared alias `redis` | `6379` | `redis-cli PING` |
| `monitoring-service` | project `monitoring-server` | Grafana host default `3005` | Grafana `/api/health`, Prometheus `/-/ready` |

- 구현 레포 기준으로 보면 repo 이름과 runtime host가 항상 같지는 않다.
- current gateway의 canonical upstream env는 `EDITOR_SERVICE_URL=http://editor-service:8083`, `REDIS_HOST=redis`다.

## Rules
- 공통 규칙은 여기로 복제하지 않고 [shared](../shared/README.md)를 링크한다.
- repository별 README는 `Source` 표에 GitHub repo, branch, `contract.lock.yml`을 명시한다.
- OpenAPI와 JSON Schema는 [artifacts](../artifacts/README.md)에 둔다.
- frontend repo는 OpenAPI를 직접 소유하지 않고, Gateway public route 계약을 소비한다.
