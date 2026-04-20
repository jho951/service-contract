# Monitoring Operations Contract

## Startup / Runtime
| 항목 | 값 |
| --- | --- |
| 역할 | 관측 스택 운영 runtime |
| Prometheus | `9090` |
| Grafana | `3000` |
| Loki | `3100` |
| Promtail | host log 수집 agent, public inbound 없음 |

## Operational Responsibilities
| 책임 | 설명 |
| --- | --- |
| readiness | Prometheus/Grafana/Loki ready 상태 확인 |
| config validation | scrape config, alert rule, dashboard provisioning 검증 |
| target health | 서비스별 scrape success와 latency 확인 |
| alert routing | receiver, severity, silence 정책 관리 |
| retention | metrics/log 보존 기간과 저장소 사용량 관리 |
| backup | Grafana dashboard, datasource, alert rule, persistent volume 백업 |

## Validation
| 검증 | 예시 |
| --- | --- |
| Prometheus config | `promtool check config prometheus.yml` |
| Prometheus rules | `promtool check rules alerts.yml` |
| Prometheus ready | `GET /-/ready` |
| Grafana health | `GET /api/health` |
| Loki ready | `GET /ready` |
| target health | Prometheus `up{service="<service>"}` query |

## Maintenance
| 항목 | 설명 |
| --- | --- |
| target update | `monitoring/prometheus/targets/ec2-services.yml`과 이 계약의 label 기준을 함께 갱신한다. |
| dashboard update | 공통 dashboard는 provisioning 파일로 관리하고 변경 이력을 남긴다. |
| alert update | severity, threshold, receiver 변경은 운영 영향 변경으로 기록한다. |
| retention update | 보존 기간 변경은 저장 비용과 장애 분석 요구를 함께 검토한다. |

## Notes
- Monitoring 장애는 서비스 요청 처리 장애와 분리해서 판단한다.
- Monitoring 장애 중에도 서비스 health/readiness 자체가 false로 바뀌면 안 된다.
- scrape 실패가 실제 서비스 장애인지 network/security boundary 문제인지 먼저 구분한다.
