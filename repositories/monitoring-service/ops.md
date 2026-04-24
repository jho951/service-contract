# Monitoring Operations Contract

## Startup / Runtime
| 항목 | 값 |
| --- | --- |
| 역할 | 관측 스택 운영 runtime |
| Prometheus | host `9090 -> 9090` |
| Grafana | host `3005 -> 3000` |
| Loki | host `3100 -> 3100` |
| Promtail | host log 수집 agent, public inbound 없음 |

- dev Grafana는 `monitoring-private` 외에 `auth-private`, `user-private`, `editor-private`, `authz-private` 네트워크에도 붙는다.
- dev Grafana datasource provisioning은 Prometheus 1개와 MySQL 4개(Auth/User/Editor/Authz)를 기본 적재한다.

## Operational Responsibilities
| 책임 | 설명 |
| --- | --- |
| readiness | Prometheus/Grafana/Loki ready 상태 확인 |
| config validation | Prometheus file discovery, Grafana provisioning, Loki/Promtail config 검증 |
| target health | 서비스별 scrape success와 latency 확인 |
| datasource/dashboard | Grafana datasource와 provisioning dashboard 정합성 관리 |
| retention | Loki `retention_period`와 Prometheus/Grafana volume 사용량 관리 |
| backup | Grafana data, Loki/Prometheus persistent volume 백업 기준 관리 |

## Coverage Baseline
| Target | 최소 관측 항목 | 우선 확인 포인트 |
| --- | --- | --- |
| `gateway-service` | request volume, p95 latency, 4xx/5xx, upstream failure | public `/v1/**` 오류 증가, auth proxy 실패, upstream timeout |
| `auth-service` | login/refresh 흐름, Redis/MySQL readiness, JVM/HTTP | 로그인 실패 급증, refresh 실패, 세션 저장소 문제 |
| `user-service` | signup/internal user latency, DB saturation, 4xx/5xx | signup 실패, 내부 조회 지연, DB pool 고갈 |
| `editor-service` | document/block transaction latency, conflict/error, DB health | `409` 증가, transaction 지연, persistence 오류 |
| `authz-service` | allow/deny traffic, Redis fallback, DB/HTTP latency | `ready DOWN`, Redis cache miss 급증, 관리자 verify 지연 |
| `redis-server exporter` | `redis_up`, memory, clients, evictions | 메모리 압박, 연결 급증, eviction 발생 |

## Validation
| 검증 | 예시 |
| --- | --- |
| Prometheus config | `promtool check config monitoring/prometheus/prometheus.yml` |
| dev compose | `docker compose -f docker/dev/compose.yml config` |
| prod compose | `docker compose -f docker/prod/compose.yml config` |
| Prometheus ready | `GET /-/ready` |
| Grafana health | `GET /api/health` |
| Loki ready | `GET /ready` |
| Grafana datasource provisioning | `docker/dev/grafana/provisioning/datasources/prometheus.yml`, `docker/dev/grafana/provisioning/datasources/mysql.yml` |
| target health | Prometheus `up{service="<service>"}` query |
| service error rate | `rate(http_server_requests_seconds_count{service="<service>",status=~"5.."}[5m])` |
| service latency | `histogram_quantile(0.95, sum by (le, service) (rate(http_server_requests_seconds_bucket{service="<service>"}[5m])))` |
| Redis exporter | `redis_up{service="redis-server"}` 또는 `up{service="redis-server"}` |
| Redis saturation | `redis_memory_used_bytes`, `redis_connected_clients`, `redis_evicted_keys_total` |

## Maintenance
| 항목 | 설명 |
| --- | --- |
| target update | `monitoring/prometheus/targets/ec2-services.yml`, `monitoring/prometheus/targets/local-services.yml`, 이 계약의 label 기준을 함께 갱신한다. |
| dashboard update | 공통 dashboard는 provisioning 파일로 관리하고 변경 이력을 남긴다. |
| datasource update | Grafana datasource UID/name 변경은 `docker/dev/grafana/provisioning/datasources/*.yml`과 dashboard query를 함께 검증한다. |
| retention update | `monitoring/loki/loki-config.yml`의 retention 변경은 저장 비용과 장애 분석 요구를 함께 검토한다. |
| redis integration update | Redis exporter 이름, 포트, auth, target label 변경은 `redis-service` contract와 함께 갱신한다. |

## Alert Backlog
현재 구현에는 Alertmanager가 없지만, alerting을 도입하면 아래 기준을 기본선으로 삼는다.

| Area | Candidate Rule |
| --- | --- |
| availability | `up == 0` 또는 readiness 실패 지속 |
| edge | Gateway 5xx rate 급증, upstream timeout 증가 |
| auth | login/refresh 오류율 급증, Redis/MySQL readiness 실패 |
| authz | `/permissions/internal/admin/verify` latency 급증, Redis fallback 지속 |
| editor | transaction error/409 급증, DB saturation |
| redis | memory pressure, eviction 발생, connected clients 급증 |

## Notes
- 현재 구현 repo에는 Alertmanager나 Prometheus alert rule 파일이 없다. alerting을 도입하면 별도 contract section과 validation 항목을 추가한다.
- Monitoring 장애는 서비스 요청 처리 장애와 분리해서 판단한다.
- Monitoring 장애 중에도 서비스 health/readiness 자체가 false로 바뀌면 안 된다.
- scrape 실패가 실제 서비스 장애인지 network/security boundary 문제인지 먼저 구분한다.
- Grafana에서 MySQL datasource가 비어 보이면 private network attach와 `GRAFANA_*_MYSQL_*` env 주입부터 확인한다.
