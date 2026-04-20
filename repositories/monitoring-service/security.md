# Monitoring Security Contract

Monitoring stack은 운영 정보를 모으므로 public surface로 취급하지 않는다.

## Access Boundary
| Surface | 접근 기준 |
| --- | --- |
| Grafana | operator IP/VPN 또는 private network only |
| Prometheus UI/API | operator IP/VPN 또는 private network only |
| Loki API | operator IP/VPN 또는 private network only |
| Promtail | 외부 inbound 없음 |
| metrics endpoints | monitoring-service와 operator network only |

## Secret Handling
| 항목 | 기준 |
| --- | --- |
| Grafana admin password | repo에 평문 저장 금지 |
| datasource credentials | secret manager 또는 host env로 주입 |
| webhook token | repo에 평문 저장 금지 |
| application logs | token, cookie, authorization header, internal secret redaction |
| metrics labels | user id, email, token, raw path parameter 같은 high-cardinality/민감값 금지 |

## Rules
- Grafana anonymous access는 production에서 비활성화한다.
- Prometheus와 Loki는 public internet에 직접 노출하지 않는다.
- 서비스의 `/actuator/prometheus`는 인증 또는 network boundary로 보호한다.
- dashboard 권한 변경, datasource 변경, alert receiver 변경은 감사 대상이다.
- log query 결과를 외부에 공유할 때 credential과 개인정보가 포함되지 않았는지 확인한다.
