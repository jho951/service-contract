# Monitoring Contract

`monitoring-service`는 Prometheus, Grafana, Loki, Promtail 또는 동등한 관측 스택의 운영 계약을 소유한다.
비즈니스 API를 제공하는 서비스가 아니라 metrics/logs/dashboard/retention/operator endpoint 기준을 고정하는 infra repo다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/monitoring-service |
| Branch | `main` |
| Contract Lock | `contract.lock.yml` |

## 책임 경계
| 영역 | 책임 |
| --- | --- |
| Metrics collection | 서비스별 scrape target, path, label 기준 |
| Service observability baseline | health/readiness/Prometheus 노출과 dashboard focus 기준 |
| Logs collection | application/system log 수집 경계와 redaction 기준 |
| Dashboards | 공통 dashboard provisioning과 권한 기준 |
| Redis integration | Redis exporter target, memory/connection/eviction 관측 기준 |
| Alerts | 현재 구현 없음. alert rule/receiver 도입 시 이 계약에 먼저 반영 |
| Retention | metrics/log 보존 기간과 저장소 운영 기준 |
| Operations | config 검증, readiness, backup, restore, 장애 대응 |

## 문서
- [Targets Contract](targets.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Shared Monitoring Contract](../../shared/monitoring.md)
- [Monitoring Ops OpenAPI](../../artifacts/openapi/monitoring-service.ops.v1.yaml)
- [Common Audit Contract](../../shared/audit.md)

## 계약 원칙
- Monitoring은 서비스 runtime의 진실을 소유하지 않는다. 각 서비스의 health, readiness, metric 의미는 해당 서비스 계약이 우선한다.
- Monitoring은 현재 scrape target, label, dashboard, retention, operator endpoint의 운영 기준을 소유한다.
- Monitoring baseline에는 `gateway-service`, `auth-service`, `user-service`, `editor-service`, `authz-service`, `redis-server exporter`가 포함된다.
- public user traffic은 Monitoring으로 라우팅하지 않는다.
- Grafana, Prometheus, Loki 접근은 operator IP/VPN 또는 private network로 제한한다.
- credential, token, cookie, internal secret은 metrics label이나 log body에 남기지 않는다.
- Prometheus는 code 기준 `monitoring/prometheus/targets/ec2-services.yml` file discovery를 사용하고, dev compose는 `local-services.yml`을 같은 container path로 overlay한다.
- Redis는 `redis-server` label을 가진 exporter와 애플리케이션의 Redis dependency metric을 함께 봐야 한다.
- 서비스별 dashboard는 최소한 health/readiness, request latency/error, dependency(DB/Redis), service-owned domain panel을 포함한다.
- target 추가/삭제, 공통 label 변경, operator endpoint 변경은 contract 변경으로 보고 `contract.lock.yml`을 갱신한다.
- 현재 구현 repo의 compose project 이름은 `monitoring-server`다.
- Grafana host 기본 포트는 compose 기준 `3005 -> 3000`이다.
- dev Grafana는 `auth-private`, `user-private`, `documents-private`, `authz-private` 네트워크에도 붙어 각 서비스의 private MySQL에 직접 접근할 수 있다.
- dev Grafana datasource provisioning은 `docker/dev/grafana/provisioning/datasources/prometheus.yml`, `docker/dev/grafana/provisioning/datasources/mysql.yml`을 사용하며, MySQL datasource는 Auth/User/Editor/Authz 네 개를 기본 등록한다.
- target file과 관련 런타임 이름 사이에는 `gateway-service`, `documents-service`, `redis-server`, `central-redis-exporter(-dev)`, `monitoring-server` 같은 이름이 함께 쓰일 수 있다.

## 운영 배포 자산

- EC2 image-only 배포 기준 산출물은 구현 repo의 `deploy/ec2/` 아래에 둔다.
- 기본 파일은 `docker-compose.yml`, `.env.production.example`, `README.md`다.
- Grafana를 외부에 제한적으로 노출할 필요가 있으면 host Nginx example을 함께 둔다.
