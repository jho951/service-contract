# Monitoring Contract

`monitoring-service`는 Prometheus, Grafana, Loki, Promtail 또는 동등한 관측 스택의 운영 계약을 소유한다.
비즈니스 API를 제공하는 서비스가 아니라 metrics/logs/dashboard/alert 기준을 고정하는 infra repo다.

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
| Logs collection | application/system log 수집 경계와 redaction 기준 |
| Dashboards | 공통 dashboard provisioning과 권한 기준 |
| Alerts | 공통 alert rule, notification route, silence 운영 기준 |
| Retention | metrics/log 보존 기간과 저장소 운영 기준 |
| Operations | config 검증, readiness, backup, restore, 장애 대응 |

## 문서
- [Targets Contract](targets.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Common Audit Contract](../../shared/audit.md)

## 계약 원칙
- Monitoring은 서비스 runtime의 진실을 소유하지 않는다. 각 서비스의 health, readiness, metric 의미는 해당 서비스 계약이 우선한다.
- Monitoring은 scrape target, label, dashboard, alert, retention의 운영 기준을 소유한다.
- public user traffic은 Monitoring으로 라우팅하지 않는다.
- Grafana, Prometheus, Loki 접근은 operator IP/VPN 또는 private network로 제한한다.
- credential, token, cookie, internal secret은 metrics label이나 log body에 남기지 않는다.
- target 추가/삭제, 공통 label 변경, alert rule 변경은 contract 변경으로 보고 `contract.lock.yml`을 갱신한다.
