# Monitoring Targets Contract

Prometheus target은 `monitoring-service`의 file discovery 설정을 기준으로 관리한다.
EC2 분리 배포에서는 실제 private IP/DNS를 사용하고, public DNS를 scrape target으로 쓰지 않는다.

## Target Source
| 항목 | 값 |
| --- | --- |
| prod 기준 파일 | `monitoring/prometheus/targets/ec2-services.yml` |
| dev overlay 파일 | `monitoring/prometheus/targets/local-services.yml` |
| Spring metrics path | `/actuator/prometheus` |
| Redis exporter path | `/metrics` |
| target network | private subnet, VPC, Docker internal network 중 하나 |

## Current Labels
| Label | 의미 | 예시 |
| --- | --- | --- |
| `service` | 현재 구현 target label | `auth-service`, `user-service`, `editor-service`, `authz-service`, `gateway-service`, `redis-server` |
| `ec2` | target이 속한 배치 노드 | `ec2-1`, `ec2-2`, `ec2-3` |
| `__metrics_path__` | target별 metrics path override | `/actuator/prometheus`, `/metrics` |

## Initial Targets
| Service | Endpoint | Labels |
| --- | --- | --- |
| `auth-service` | `<ec2-2-private>:8081/actuator/prometheus` | `service=auth-service`, `ec2=ec2-2` |
| `user-service` | `<ec2-2-private>:8082/actuator/prometheus` | `service=user-service`, `ec2=ec2-2` |
| `editor-service` | `<ec2-2-private>:8083/actuator/prometheus` | `service=editor-service`, `ec2=ec2-2` |
| `authz-service` | `<ec2-2-private>:8084/actuator/prometheus` | `service=authz-service`, `ec2=ec2-2` |
| `gateway-service` | `<ec2-1-private>:8080/actuator/prometheus` | `service=gateway-service`, `ec2=ec2-1` |
| `redis-server exporter` | `<ec2-3-private>:9121/metrics` | `service=redis-server`, `ec2=ec2-3` |

## Local Dev Overlay
dev compose는 `local-services.yml`을 `/etc/prometheus/targets/ec2-services.yml`로 mount해서 같은 file discovery 경로를 재사용한다.

| Service | Endpoint | Labels |
| --- | --- | --- |
| `auth-service` | `auth-service:8081/actuator/prometheus` | `service=auth-service`, `ec2=ec2-2` |
| `user-service` | `user-service:8082/actuator/prometheus` | `service=user-service`, `ec2=ec2-2` |
| `editor-service` | `editor-service:8083/actuator/prometheus` | `service=editor-service`, `ec2=ec2-2` |
| `authz-service` | `authz-service:8084/actuator/prometheus` | `service=authz-service`, `ec2=ec2-2` |
| `gateway-service` | `gateway-service:8080/actuator/prometheus` | `service=gateway-service`, `ec2=ec2-1` |
| `redis-server exporter` | `redis-exporter:9121/metrics` | `service=redis-server`, `ec2=ec2-3` |

## Service Coverage
| Observed Service | Metrics Path | Health / Ready Reference | Dashboard Focus |
| --- | --- | --- | --- |
| `gateway-service` | `/actuator/prometheus` | `/health`, `/ready`, public `/v1/health`, `/v1/ready` | edge traffic, upstream latency, auth proxy failure |
| `auth-service` | `/actuator/prometheus` | `/health`, `/ready`, status alias `/`, `/v1` | login/refresh, Redis session store, MySQL readiness |
| `user-service` | `/actuator/prometheus` | `/health`, `/ready` | signup/internal lookup latency, DB saturation |
| `editor-service` | `/actuator/prometheus` | `/actuator/health`, `/actuator/health/readiness` | document/block transaction latency, conflict/error |
| `authz-service` | `/actuator/prometheus` | `/health`, `/ready`, `/actuator/health` | admin verify latency, Redis fallback, permission traffic |
| `redis-server exporter` | `/metrics` | `redis-cli PING` | memory, clients, evictions, availability |

## File Discovery Example
```yaml
- targets:
    - <ec2-1-private>:8080
  labels:
    service: gateway-service
    ec2: ec2-1
    __metrics_path__: /actuator/prometheus
```

## Rules
- `service` label은 current target file이 실제로 쓰는 값을 우선하며 현재 baseline은 `gateway-service`, `auth-service`, `user-service`, `editor-service`, `authz-service`, `redis-server`다.
- 현재 구현 baseline에는 `env`, `role`, `instance`, `nginx`, `node` label/target이 없다. 이를 추가하면 contract와 dashboard/query를 함께 갱신한다.
- dev는 Docker service name과 `redis-exporter`를 사용하고, prod는 EC2 private DNS/IP와 `redis-server` label을 유지한다.
- Redis는 exporter target만 보는 것이 아니라 `auth-service`, `authz-service`, `gateway-service`의 dependency metric과 함께 상관 분석한다.
- path가 다른 target은 Prometheus scrape job을 분리하거나 `__metrics_path__` relabeling을 명시한다.
- actuator metrics endpoint는 Gateway/operator network에서만 접근 가능해야 한다.
- application metric name은 각 서비스가 소유하지만, 공통 label 변경은 이 문서에 먼저 반영한다.
- target이 제거되면 dashboard query와 provisioning 설정에 orphan reference가 남지 않는지 확인한다.
