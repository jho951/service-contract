# Monitoring Targets Contract

Prometheus target은 `monitoring-service`의 file discovery 설정을 기준으로 관리한다.
EC2 분리 배포에서는 실제 private IP/DNS를 사용하고, public DNS를 scrape target으로 쓰지 않는다.

## Target Source
| 항목 | 값 |
| --- | --- |
| 기준 파일 | `monitoring/prometheus/targets/ec2-services.yml` |
| Spring metrics path | `/actuator/prometheus` |
| Redis exporter path | `/metrics` |
| Node exporter path | `/metrics` |
| target network | private subnet, VPC, Docker internal network 중 하나 |

## Required Labels
| Label | 의미 | 예시 |
| --- | --- | --- |
| `env` | 배포 환경 | `dev`, `staging`, `prod` |
| `service` | 표준 서비스명 | `gateway`, `auth`, `authz`, `user`, `block`, `redis`, `nginx`, `node` |
| `role` | target 역할 | `app`, `cache`, `edge`, `node`, `gateway` |
| `instance` | host 또는 task 식별자 | `ec2-1`, `ec2-2`, `ec2-3` |

## Initial Targets
| Service | Endpoint | Labels |
| --- | --- | --- |
| EC2-1 Nginx exporter | `<ec2-1-private>:9113/metrics` | `service=nginx`, `role=edge` |
| `gateway-service` | `<ec2-1-private>:8080/actuator/prometheus` | `service=gateway`, `role=gateway` |
| `auth-service` | `<ec2-2-private>:8081/actuator/prometheus` | `service=auth`, `role=app` |
| `user-service` | `<ec2-2-private>:8082/actuator/prometheus` | `service=user`, `role=app` |
| `editor-service` | `<ec2-2-private>:8083/actuator/prometheus` | `service=block`, `role=app` |
| `authz-service` | `<ec2-2-private>:8084/actuator/prometheus` | `service=authz`, `role=app` |
| `redis-service` | `<ec2-3-private>:9121/metrics` | `service=redis`, `role=cache` |
| EC2 hosts | `<ec2-private>:9100/metrics` | `service=node`, `role=node` |

## File Discovery Example
```yaml
- targets:
    - <ec2-1-private>:8080
  labels:
    env: prod
    service: gateway
    role: gateway
    instance: ec2-1
    metrics_path: /actuator/prometheus
```

## Rules
- `service` label은 repo 이름이 아니라 짧은 표준 이름을 사용한다.
- path가 다른 target은 Prometheus scrape job을 분리하거나 `__metrics_path__` relabeling을 명시한다.
- actuator metrics endpoint는 Gateway/operator network에서만 접근 가능해야 한다.
- application metric name은 각 서비스가 소유하지만, 공통 label 변경은 이 문서에 먼저 반영한다.
- target이 제거되면 dashboard와 alert rule에서 orphan query가 남지 않는지 확인한다.
