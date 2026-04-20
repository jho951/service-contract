# EC2 Deployment Topology

이 문서는 초기 EC2 배포 기준을 정리한다. 목표는 외부 진입점을 EC2-1의 Nginx/Gateway로 단일화하고, 내부 서비스와 Redis/Monitoring은 private network 중심으로 운영하는 것이다.

## 배포 배치
| EC2 | Component | Role |
| --- | --- | --- |
| EC2-1 | `nginx` | 외부 HTTP/HTTPS 진입점, TLS 종료, reverse proxy |
| EC2-1 | `gateway-service` | public API routing, 인증 프록시, 공통 헤더 정규화 |
| EC2-2 | `auth-service` | 로그인, refresh, session, JWT/JWKS |
| EC2-2 | `user-service` | 사용자 프로필, 상태, visibility |
| EC2-2 | `authz-service` | 권한 판단, RBAC, policy, introspection |
| EC2-2 | `editor-service` | 문서/블록 도메인 API |
| EC2-3 | `redis` | session/cache/rate-limit/policy cache 저장소 |
| EC2-3 | `monitoring` | Prometheus/Grafana 또는 동등한 모니터링 구성 |

## 요청 흐름
```txt
Client
  -> EC2-1 nginx:80/443
  -> EC2-1 gateway-service
  -> EC2-2 auth-service/user-service/authz-service/editor-service
  -> EC2-3 redis

Monitoring
  -> EC2-1 metrics
  -> EC2-2 metrics
  -> EC2-3 metrics
```

## 네트워크 원칙
- Public inbound는 EC2-1의 `80`, `443`만 허용한다.
- EC2-2의 backend service는 EC2-1에서만 접근 가능해야 한다.
- EC2-3의 Redis는 EC2-2에서만 접근하는 것을 기본으로 하고, Gateway가 Redis를 직접 사용하면 EC2-1도 허용한다.
- 서비스 간 통신에는 public IP를 사용하지 않는다. EC2 private IP, private DNS, 또는 내부 service discovery 이름을 사용한다.
- SSH는 모든 EC2에서 운영자 고정 IP 또는 VPN 대역만 허용한다.
- Grafana 같은 운영 UI는 public open을 피하고, 운영자 IP/VPN만 허용한다.

## 보안 그룹 기준
| Target | Inbound Rule |
| --- | --- |
| EC2-1 `nginx` | `80`, `443` from `0.0.0.0/0` |
| EC2-1 `gateway-service` | localhost 또는 EC2-1 내부 Docker network only |
| EC2-2 services | service ports from EC2-1 security group only |
| EC2-3 `redis` | `6379` from EC2-2 security group, optionally EC2-1 security group |
| EC2-3 `monitoring` | Grafana from operator IP/VPN only |
| all EC2 SSH | `22` from operator IP/VPN only |

## 포트 예시
실제 포트는 각 서비스 레포의 실행 설정을 우선한다. 아래 값은 초기 배포용 기본 예시다.

| Component | Port | Exposure |
| --- | --- | --- |
| `nginx` | `80`, `443` | public |
| `gateway-service` | `8080` | EC2-1 local/internal |
| `auth-service` | `8081` | private |
| `user-service` | `8082` | private |
| `editor-service` / `documents-service` | `8083` | private |
| `authz-service` / `permission-service` | `8084` | private |
| `redis` | `6379` | private |
| `prometheus` | `9090` | private/operator only |
| `grafana` | `3000` | operator only |

## Nginx 기준
Nginx는 외부 요청을 Gateway로만 전달한다. Backend service로 직접 proxy하지 않는다.

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

TLS를 적용하면 `443 ssl` server block에서 같은 Gateway upstream을 사용한다. `80`은 `443`으로 redirect하는 구성을 권장한다.

## Gateway 환경 변수 예시
Gateway는 EC2-2 service를 private address로 호출한다.

```yaml
AUTH_SERVICE_URL: http://10.0.x.x:8081
USER_SERVICE_URL: http://10.0.x.x:8082
BLOCK_SERVICE_URL: http://10.0.x.x:8083
PERMISSION_SERVICE_URL: http://10.0.x.x:8084
PERMISSION_ADMIN_VERIFY_URL: http://10.0.x.x:8084/permissions/internal/admin/verify
REDIS_HOST: 10.0.x.x
REDIS_PORT: 6379
```

고정 private IP를 직접 넣는 방식은 단순하지만, EC2 교체 시 설정 변경이 필요하다. 운영 안정성을 높이려면 private DNS, Route 53 private hosted zone, 또는 Docker/Compose network alias 같은 이름 기반 접근을 우선 검토한다.

## 현재 서비스 코드 기준 확인
2026-04-20 로컬 서비스 레포 기준 확인 결과다.

| Service Repo | Current Runtime Shape | EC2 3대 배포 시 확인할 점 |
| --- | --- | --- |
| `gateway-service` | `gateway:8080`, prod compose default upstream은 `auth-service:8081`, `user-service:8082`, `documents-service:8083`, `permission-service:8084`, `central-redis:6379` | Docker DNS 이름은 단일 호스트 external network 전제다. EC2 분리 배포에서는 upstream과 Redis host를 EC2 private IP/DNS로 override한다. 현재 prod compose는 `8080:8080`을 publish하므로 Nginx만 접근하도록 host bind 또는 security group을 제한한다. |
| `auth-service` | prod profile port `8081`, compose service name `auth-service`, MySQL은 `auth-private` internal network | EC2-2에서 실행하고 Gateway만 접근하게 둔다. Redis/User 연동 env가 있으면 EC2-3 Redis와 EC2-2 User private endpoint를 가리키게 한다. |
| `user-service` | prod profile port `8082`, compose alias `user-service`, MySQL은 `user-private` internal network | EC2-2에서 실행하고 public port publish 없이 Gateway/Auth만 접근하게 둔다. |
| `editor-service` | `documents-service:8083`, MySQL은 `documents-private` internal network | Gateway의 `BLOCK_SERVICE_URL`은 `8083`으로 맞춘다. prod compose는 `DOCUMENTS_SERVICE_HOST_BIND`로 EC2-2 private IP에 publish한다. |
| `authz-service` | `permission-service:8084`, Redis는 external 중앙 Redis 사용 | `REDIS_HOST`는 EC2-3 private IP/DNS로 설정한다. prod compose는 `AUTHZ_SERVICE_HOST_BIND`로 EC2-2 private IP에 publish한다. |
| `redis-service` | prod Redis `6379`, exporter `9121`, password와 bind host required | EC2-3 security group으로 `6379`/`9121` 접근원을 제한한다. `REDIS_BIND_HOST`와 `REDIS_EXPORTER_BIND_HOST`는 EC2-3 private IP로 설정한다. |
| `monitoring-service` | Prometheus/Grafana/Loki/Promtail compose, Prometheus target은 file discovery 기준 | `monitoring/prometheus/targets/ec2-services.yml`의 target을 실제 EC2 private DNS/IP로 맞춘다. Grafana/Prometheus/Loki host port는 운영자 IP/VPN으로만 열어야 한다. |

현재 서비스 compose들은 대부분 `service-backbone-shared` external Docker network를 전제로 한다. 이 네트워크 이름은 한 EC2 안의 컨테이너 간 DNS에는 유효하지만, EC2 간 DNS로 동작하지 않는다. 따라서 3대 EC2 배포에서는 다음 둘 중 하나를 선택한다.

1. 각 service URL과 Redis/Monitoring target을 EC2 private IP/DNS로 override한다.
2. Docker Swarm overlay network, ECS, Kubernetes, Consul, Route 53 private hosted zone 같은 cross-host service discovery를 도입한다.

## 서비스 레포 반영 사항
2026-04-20 기준으로 EC2 3대 배포를 위해 서비스 레포의 prod 설정은 다음 방향으로 정렬한다.

| Repo | Prod Setting |
| --- | --- |
| `gateway-service` | `GATEWAY_HOST_BIND` 기본값은 `127.0.0.1`로 두고 Nginx만 Gateway host port에 접근하게 한다. `AUTH_SERVICE_URL`, `USER_SERVICE_URL`, `BLOCK_SERVICE_URL`, `REDIS_HOST`는 prod compose에서 required로 둔다. |
| `auth-service` | `AUTH_SERVICE_HOST_BIND`와 `AUTH_SERVICE_HOST_PORT`로 EC2-2 private IP에 `8081`을 publish한다. |
| `user-service` | `USER_SERVICE_HOST_BIND`와 `USER_SERVICE_HOST_PORT`로 EC2-2 private IP에 `8082`를 publish한다. |
| `editor-service` | `DOCUMENTS_SERVICE_HOST_BIND`와 `DOCUMENTS_SERVICE_HOST_PORT`로 EC2-2 private IP에 `8083`을 publish한다. `/actuator/prometheus` 노출을 위해 actuator와 Prometheus registry를 포함한다. |
| `authz-service` | prod compose의 embedded Redis를 제거하고 `REDIS_HOST`를 required로 둔다. `AUTHZ_SERVICE_HOST_BIND`와 `AUTHZ_SERVICE_HOST_PORT`로 EC2-2 private IP에 `8084`를 publish한다. |
| `redis-service` | `REDIS_PASSWORD`, `REDIS_BIND_HOST`, `REDIS_EXPORTER_BIND_HOST`를 prod compose에서 required로 둔다. `REDIS_BIND_HOST`와 exporter bind host는 EC2-3 private IP를 사용한다. |
| `monitoring-service` | Prometheus/Grafana/Loki host port는 기본 `127.0.0.1` bind다. Prometheus target은 `monitoring/prometheus/targets/ec2-services.yml` file discovery로 관리한다. |

EC2 private IP bind 변수는 DNS 이름이 아니라 실제 host interface IP여야 한다. 예를 들어 EC2-2 private IP가 `10.0.0.10`이면 `AUTH_SERVICE_HOST_BIND=10.0.0.10`, `USER_SERVICE_HOST_BIND=10.0.0.10`, `DOCUMENTS_SERVICE_HOST_BIND=10.0.0.10`, `AUTHZ_SERVICE_HOST_BIND=10.0.0.10`처럼 설정한다.

## 배포 순서
1. EC2-3에 Redis를 먼저 배포하고 private inbound를 제한한다.
2. EC2-2에 `auth-service`, `user-service`, `authz-service`, `editor-service`를 배포한다.
3. EC2-2 service가 Redis에 연결되는지 확인한다.
4. EC2-1에 `gateway-service`를 배포하고 EC2-2 service upstream을 설정한다.
5. EC2-1에 Nginx를 배포하고 Gateway로 reverse proxy한다.
6. EC2-3에 monitoring을 배포하고 EC2-1/2/3 metrics target을 등록한다.
7. 외부에서 Nginx health endpoint와 대표 API smoke test를 실행한다.

## Docker Compose 운영 기준
각 EC2에서 Docker Compose를 사용한다면 최소 기준은 다음과 같다.

- 서비스별 `restart: unless-stopped`를 설정한다.
- container log rotation을 설정해 디스크 고갈을 방지한다.
- healthcheck를 추가하고, Gateway/Nginx upstream은 health endpoint 기준으로 검증한다.
- secret, token, DB password는 repository에 commit하지 않고 EC2 환경 변수, `.env`, secret manager 중 하나로 주입한다.
- EC2-2는 서비스가 4개 모이므로 CPU/RAM 사용량을 우선 관찰한다.

## Monitoring 기준
초기 monitoring target은 다음을 포함한다.

| Target | Check |
| --- | --- |
| EC2-1 Nginx | request count, 4xx/5xx, upstream latency |
| EC2-1 Gateway | JVM/app health, route error rate, auth proxy failures |
| EC2-2 Services | JVM/app health, request latency, dependency failures |
| EC2-3 Redis | memory, connection count, evicted keys, latency |
| EC2 hosts | CPU, memory, disk, network |

Alert는 최소한 다음 조건에 건다.

- Gateway 또는 backend healthcheck 실패
- Redis 연결 실패 또는 memory pressure
- disk usage high
- 5xx rate 증가
- p95 latency 급증

## 운영 체크리스트
- EC2-1 외에는 public inbound가 열려 있지 않은지 확인한다.
- EC2-2 service port가 EC2-1 security group에서만 접근 가능한지 확인한다.
- Redis `6379`가 public internet에 노출되지 않았는지 확인한다.
- Gateway가 backend를 public IP가 아닌 private address로 호출하는지 확인한다.
- Nginx가 `X-Forwarded-For`, `X-Forwarded-Proto`, `Host` header를 전달하는지 확인한다.
- 서비스 로그에 secret/token 원문이 남지 않는지 확인한다.
- 재부팅 후 Docker service와 container가 자동 복구되는지 확인한다.

## 확장 방향
초기에는 EC2-2에 backend service를 모아도 된다. 트래픽이나 장애 격리가 필요해지면 다음 순서로 분리한다.

1. `auth-service`를 별도 EC2 또는 autoscaling group으로 분리한다.
2. `user-service`와 `editor-service`를 도메인별로 분리한다.
3. Redis는 managed Redis 또는 전용 HA 구성으로 이전한다.
4. Gateway는 EC2-1 단일 구성을 load balancer + 다중 Gateway 구성으로 확장한다.
