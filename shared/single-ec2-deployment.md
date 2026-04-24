# Single EC2 Deployment Contract

이 문서는 현재 단일 EC2 `m7i-flex.large` 기준의 실제 배포 모드를 정의한다.

기본 선언:

```text
MSA를 논리적으로 유지하되, 배포는 물리적으로 1대 EC2에 통합한다.
```

대상:

- `gateway-service`
- `auth-service`
- `user-service`
- `authz-service`
- `editor-service`
- `redis-service`
- `monitoring-service`
- `editor-page`
- `explain-page`

## 1. 목적

이 모드는 다음 조건에서 사용한다.

- 현재는 단일 EC2 리소스 안에서 backend 7개와 frontend 2개를 함께 안정적으로 운영해야 한다.
- 운영 서버는 `m7i-flex.large`를 기준으로 CPU/메모리 여유를 확보한다.
- 서비스 repo와 계약은 MSA로 유지하되, 실제 런타임은 단일 host에서 운영한다.

## 2. 배포 원칙

1. 단일 EC2 한 대에서 `docker compose`로 전체 서비스를 실행한다.
2. Gateway만 외부 진입점을 가진다.
3. 나머지 서비스는 같은 Docker network 안에서 service name alias로만 호출한다.
4. Redis는 같은 host 내부 network로만 노출한다.
5. Monitoring은 같은 host에 기본 포함으로 올린다.
6. 운영형 Compose는 EC2에서 빌드하지 않고, CI/CD가 Amazon ECR에 push한 이미지만 pull해서 사용한다.
7. 외부 공개는 Nginx reverse proxy가 담당하고, 앱 포트는 `127.0.0.1` bind 또는 Docker network 내부에만 둔다.
8. 등록 도메인은 하나만 사용하고, 공개 엔드포인트는 같은 등록 도메인 아래 서브도메인으로 분리한다.
9. 운영 EC2에는 앱 소스를 clone 하지 않고, repo가 제공하는 `deploy/ec2` bundle만 복사해 둔다.

## 3. 이미지 정책

운영 배포에서 모든 서비스는 아래 규칙을 따른다.

- registry: Amazon ECR
- immutable deploy tag: `${GITHUB_SHA}`
- floating tag: `latest`는 `main` 또는 `master`에서만 발행
- prod compose: `build:` 대신 required `image:` 변수 사용
- EC2 배포 명령: 전체 초기 기동은 `docker compose pull && docker compose up -d`, 서비스 단건 반영은 `docker compose pull <service> && docker compose up -d <service>`
- 서드파티 runtime 이미지(`mysql`, `redis_exporter` 등)는 env 변수로 분리하고, 운영에서는 가능하면 ECR mirror 또는 사내 registry로 대체한다.

repository 이름 규칙:

| 서비스 | ECR repository 예시 |
| --- | --- |
| `gateway-service` | `prod-gateway-service` |
| `auth-service` | `prod-auth-service` |
| `user-service` | `prod-user-service` |
| `authz-service` | `prod-authz-service` |
| `editor-service` | `prod-editor-service` |
| `redis-service` | `prod-redis-service` |
| `monitoring-service` prometheus | `prod-monitoring-service-prometheus` |
| `monitoring-service` grafana | `prod-monitoring-service-grafana` |
| `monitoring-service` loki | `prod-monitoring-service-loki` |
| `monitoring-service` promtail | `prod-monitoring-service-promtail` |
| `editor-page` | `prod-editor-page` |
| `explain-page` | `prod-explain-page` |

공통 third-party runtime 이미지 override 예시:

```env
AUTH_MYSQL_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/mirror-mysql:8.0
USER_MYSQL_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/mirror-mysql:8.4
EDITOR_MYSQL_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/mirror-mysql:8.0
REDIS_EXPORTER_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/mirror-redis-exporter:v1.67.0
```

## 4. 배포 체크리스트

### EC2

- Amazon Linux 2023 또는 Ubuntu LTS 한 대를 준비한다.
- 인스턴스 타입은 `m7i-flex.large`를 기본으로 본다.
- public IP 또는 Elastic IP를 하나만 붙인다.
- root volume은 최소 `20GB`, monitoring 데이터까지 고려하면 `30GB` 이상을 권장한다.

### Security Group

- inbound `22/tcp`: 운영자 고정 IP만 허용
- inbound `80/tcp`: 외부 공개가 필요하면 허용
- inbound `443/tcp`: TLS reverse proxy를 둘 경우 허용
- inbound `8080/tcp`: 기본 비권장, reverse proxy 없이 gateway를 직접 공개할 때만 제한적으로 허용
- inbound `3000/tcp`: 기본 비권장, explain-page 또는 Grafana direct publish에만 제한적으로 허용
- 나머지 `8081`, `8082`, `8083`, `8084`, `6379`, `9090`, `3100`은 외부 inbound를 열지 않는다

### Host Runtime

- Docker Engine 설치
- Docker Compose plugin 설치
- Git 설치
- 로그/볼륨 저장용 디렉터리 생성
- `docker login` 또는 `aws ecr get-login-password` 기반 ECR 인증 준비
- 실제 bootstrap 템플릿은 [../templates/single-ec2/user_data.sh.tftpl](../templates/single-ec2/user_data.sh.tftpl)을 기준으로 한다.
- 7개 서비스 자동 배포까지 포함한 완성형은 [../templates/single-ec2/user_data.full-stack.sh.tftpl](../templates/single-ec2/user_data.full-stack.sh.tftpl)을 기준으로 한다.
- 앱 레포 clone 없이 바로 올리려면 [../templates/single-ec2/deploy-bundle/README.md](../templates/single-ec2/deploy-bundle/README.md)의 deploy bundle을 우선 사용한다.
- deploy bundle은 `./scripts/deploy-stack.sh up gateway-service` 같은 서비스 단건 반영도 지원하는 쪽을 기준으로 본다.

권장 디렉터리:

```text
/opt/services/gateway-service
/opt/services/auth-service
/opt/services/user-service
/opt/services/authz-service
/opt/services/editor-service
/opt/services/redis-service
/opt/services/monitoring-service
/opt/services/shared
```

repo별 EC2 bundle 기준:

| Repo | 권장 bundle 경로 |
| --- | --- |
| `gateway-service` | `deploy/ec2/` |
| `auth-service` | `deploy/ec2/` |
| `user-service` | `deploy/ec2/` |
| `authz-service` | `deploy/ec2/` |
| `editor-service` | `deploy/ec2/` |
| `redis-service` | `deploy/ec2/` |
| `monitoring-service` | `deploy/ec2/` |
| `editor-page` | `deploy/ec2/` |
| `explain-page` | `deploy/ec2/` |

### Docker Network

- 공통 network 이름은 `service-backbone-shared`로 고정한다.
- gateway, auth, user, authz, editor, redis는 모두 이 network에 붙는다.
- compose override 템플릿은 [../templates/single-ec2/README.md](../templates/single-ec2/README.md)를 기준으로 복사한다.
- 실제 서비스 레포 실행은 [../templates/single-ec2/scripts/deploy-single-ec2-service.sh](../templates/single-ec2/scripts/deploy-single-ec2-service.sh) 또는 [../templates/single-ec2/scripts/deploy-single-ec2-stack.sh](../templates/single-ec2/scripts/deploy-single-ec2-stack.sh)를 기준으로 한다.
- EC2 생성 직후 자동 기동을 원하면 full-stack user data가 이 스크립트를 내부에서 호출한다.

예:

```bash
docker network create service-backbone-shared
```

### 배포 순서

1. `redis-service`
2. `auth-service`
3. `user-service`
4. `authz-service`
5. `editor-service`
6. `gateway-service`
7. `editor-page`
8. `explain-page`
9. `monitoring-service`

Gateway를 마지막에 올리는 이유는 upstream이 먼저 준비되어야 외부 진입점 health 확인이 단순하기 때문이다.
각 단계는 source build가 아니라 이미지 pull 이후 기동을 기본으로 한다.

## 5. 서비스별 포트 정책

| 서비스 | 컨테이너 포트 | Host publish | 외부 공개 여부 | 비고 |
| --- | --- | --- | --- | --- |
| `gateway-service` | `8080` | `127.0.0.1:8080` 권장 | 예 | Nginx 뒤에 두는 것을 기본값으로 본다 |
| `auth-service` | `8081` | 기본 비공개 | 아니오 | compose network alias로만 호출 |
| `user-service` | `8082` | 기본 비공개 | 아니오 | compose network alias로만 호출 |
| `editor-service` | `8083` | 기본 비공개 | 아니오 | compose network alias로만 호출 |
| `authz-service` | `8084` | 기본 비공개 | 아니오 | compose network alias로만 호출 |
| `redis-service` | `6379` | 기본 비공개 | 아니오 | host publish 금지 권장 |
| `editor-page` | `80` | `127.0.0.1:8081` 권장 | 예 | `editor.myeditor.n-e.kr`을 Nginx로 프록시 |
| `explain-page` | `3000` | `127.0.0.1:3000` 권장 | 예 | `myeditor.n-e.kr`을 Nginx로 프록시 |
| `prometheus` | `9090` | 선택 | 아니오 | 운영자 접근만 허용 |
| `grafana` | `3000` | `127.0.0.1:3005` 권장 | 제한적 | 운영자 IP 제한 권장 |
| `loki` | `3100` | 기본 비공개 | 아니오 | 내부 수집용 |

포트 정책 핵심:

- 외부 공개 포트는 gateway와 필요한 운영 포트만 연다.
- 앱 서비스 간 호출은 host port가 아니라 Docker DNS를 사용한다.
- Redis는 `6379`를 host에 publish하지 않는 것을 기본값으로 둔다.
- 프론트 2개와 gateway는 [single-ec2-edge-routing.md](single-ec2-edge-routing.md) 기준으로 Nginx 뒤에 둔다.
- `editor-page`, `explain-page`, `gateway-service`, 선택적으로 `monitoring-service(grafana)`는 host Nginx가 `127.0.0.1` bind 포트로 reverse proxy 하는 구성을 기본으로 둔다.

## 6. 서비스별 기본 호출 주소

단일 EC2 모드에서 canonical 호출 주소는 아래처럼 고정한다.

| 대상 | 값 |
| --- | --- |
| Auth | `http://auth-service:8081` |
| User | `http://user-service:8082` |
| Editor | `http://editor-service:8083` |
| Authz verify | `http://authz-service:8084/permissions/internal/admin/verify` |
| Redis | `redis` |

권장 canonical alias:

- Redis compose service key는 `redis-server`
- shared-network host 이름은 `redis`로 고정한다

## 7. 서비스별 필수 env 정책

서비스별 `.env.prod` 예시 파일은 [../templates/single-ec2/env/](../templates/single-ec2/env/)를 기준으로 사용한다.

### gateway-service

필수:

```env
GATEWAY_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-gateway-service:<sha>
AUTH_SERVICE_URL=http://auth-service:8081
USER_SERVICE_URL=http://user-service:8082
EDITOR_SERVICE_URL=http://editor-service:8083
AUTHZ_ADMIN_VERIFY_URL=http://authz-service:8084/permissions/internal/admin/verify
REDIS_HOST=redis
REDIS_PORT=6379
GATEWAY_INTERNAL_REQUEST_SECRET=<shared-internal-secret>
AUTHZ_INTERNAL_JWT_SECRET=<authz-caller-proof-secret>
```

설명:

- 단일 EC2에서는 public URL이나 private DNS를 쓰지 않는다.
- 같은 host compose alias를 upstream 주소로 사용한다.

### editor-page

필수:

```env
EDITOR_PAGE_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-editor-page:<sha>
EDITOR_PAGE_PROD_PORT=8081
VITE_GATEWAY_BASE_URL=https://api.myeditor.n-e.kr
VITE_API_BASE_URL=https://api.myeditor.n-e.kr
VITE_DOCUMENTS_API_BASE_URL=https://api.myeditor.n-e.kr
VITE_START_FRONTEND_URL=https://myeditor.n-e.kr
VITE_SITE_URL=https://editor.myeditor.n-e.kr
VITE_POST_AUTH_REDIRECT_URL=https://editor.myeditor.n-e.kr
```

운영 배포 파일:

- `deploy/ec2/docker-compose.yml`
- `deploy/ec2/.env.production.example`
- `deploy/ec2/nginx/editor-page.conf.example`

### explain-page

필수:

```env
EXPLAIN_PAGE_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-explain-page:<sha>
EXPLAIN_PAGE_PROD_PORT=3000
NEXT_PUBLIC_GATEWAY_BASE_URL=https://api.myeditor.n-e.kr
NEXT_PUBLIC_SSO_BASE_URL=https://api.myeditor.n-e.kr
NEXT_PUBLIC_START_FRONTEND_URL=https://editor.myeditor.n-e.kr
NEXT_PUBLIC_SSO_CONSUMER_CALLBACK_URL=https://editor.myeditor.n-e.kr/auth/callback
```

운영 배포 파일:

- `deploy/ec2/docker-compose.yml`
- `deploy/ec2/.env.production.example`
- `deploy/ec2/nginx/explain-page.conf.example`

### auth-service

필수:

```env
AUTH_SERVICE_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-auth-service:<sha>
USER_SERVICE_BASE_URL=http://user-service:8082
USER_SERVICE_JWT_ISSUER=auth-service
USER_SERVICE_JWT_AUDIENCE=user-service
USER_SERVICE_JWT_SUBJECT=auth-service
USER_SERVICE_JWT_SCOPE=internal
USER_SERVICE_JWT_SECRET=<user-service-shared-secret>
REDIS_HOST=redis
REDIS_PORT=6379
MYSQL_URL=<auth-db-jdbc-url>
MYSQL_USER=<auth-db-user>
MYSQL_PASSWORD=<auth-db-password>
```

### user-service

필수:

```env
USER_SERVICE_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-user-service:<sha>
USER_SERVICE_INTERNAL_JWT_ISSUER=auth-service
USER_SERVICE_INTERNAL_JWT_AUDIENCE=user-service
USER_SERVICE_INTERNAL_JWT_SCOPE=internal
USER_SERVICE_INTERNAL_JWT_SECRET=<user-service-shared-secret>
SPRING_DATASOURCE_URL=<user-db-jdbc-url>
SPRING_DATASOURCE_USERNAME=<user-db-user>
SPRING_DATASOURCE_PASSWORD=<user-db-password>
```

### authz-service

필수:

```env
AUTHZ_SERVICE_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-authz-service:<sha>
AUTHZ_INTERNAL_JWT_SECRET=<authz-caller-proof-secret>
REDIS_HOST=redis
REDIS_PORT=6379
```

비고:

- 일반 보호 서비스용 `aud=internal-services` 토큰과 authz caller proof JWT는 분리한다.

### editor-service

필수:

```env
EDITOR_SERVICE_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-editor-service:<sha>
PLATFORM_SECURITY_JWT_SECRET=<gateway-downstream-shared-secret>
PLATFORM_SECURITY_JWT_ISSUER=api-gateway
PLATFORM_SECURITY_JWT_AUDIENCE=internal-services
REDIS_HOST=redis
REDIS_PORT=6379
DB_URL_PROD=<editor-db-jdbc-url>
DB_USERNAME_PROD=<editor-db-user>
DB_PASSWORD_PROD=<editor-db-password>
```

### redis-service

필수:

```env
REDIS_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-redis-service:<sha>
REDIS_EXPORTER_IMAGE=oliver006/redis_exporter:v1.67.0
REDIS_PASSWORD=<optional-or-empty-by-policy>
```

비고:

- 현재 단일 EC2 운영 모드에서는 Redis host publish보다 Docker internal access를 우선한다.
- `REDIS_EXPORTER_IMAGE`도 Docker Hub 기본값 대신 ECR mirror를 권장한다.

### monitoring-service

필수:

```env
PROMETHEUS_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-monitoring-service-prometheus:<sha>
GRAFANA_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-monitoring-service-grafana:<sha>
LOKI_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-monitoring-service-loki:<sha>
PROMTAIL_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-monitoring-service-promtail:<sha>
GRAFANA_ADMIN_PASSWORD=<grafana-admin-password>
```

## 8. 시크릿 정렬 규칙

같은 역할의 secret은 서비스 간에 정확히 같은 값을 사용한다.

| 용도 | 맞춰야 하는 서비스 |
| --- | --- |
| Gateway -> Authz caller proof secret | `gateway-service`, `authz-service` |
| Auth -> User internal JWT secret | `auth-service`, `user-service` |
| Gateway -> downstream internal JWT secret | `gateway-service`, `user-service`, `editor-service` |
| Redis password | Redis를 참조하는 모든 서비스 |

실수 방지 원칙:

- secret 이름이 다를 수 있어도 값은 같은지 먼저 확인한다.
- browser session token, auth access token, gateway internal JWT, authz caller proof JWT를 같은 층의 credential로 취급하지 않는다.

## 9. Monitoring 정책

단일 EC2 모드에서는 monitoring을 기본 포함으로 운영한다.

### 기본 운영

- Prometheus, Grafana, Loki, Promtail을 같은 host에 함께 올린다.
- 각 서비스 health/readiness와 metrics를 같이 본다.
- Gateway 로그와 앱 로그, Redis exporter metric을 함께 확인한다.
- Prometheus/Grafana/Loki는 생략 가능하다.

### 확장 운영

- 같은 host에 `monitoring-service`를 함께 올린다.
- Grafana `3000`은 운영자 IP로만 제한한다.
- Prometheus `9090`, Loki `3100`은 외부 공개하지 않는다.

## 9. 승격 조건

아래 중 하나가 충족되면 장기 권장 아키텍처로 승격을 검토한다.

- 무중단 배포가 필수다.
- 단일 EC2 리소스 한계가 반복된다.
- 서비스별 독립 scaling이 필요하다.
- 운영자가 host 직접 접근보다 managed deployment를 원한다.

승격 방향:

```text
현재
  -> 단일 EC2 + docker compose

다음 단계
  -> shared VPC + gateway public ALB + internal ALB/private DNS
  -> app service는 ECS/Fargate + CodeDeploy blue/green
  -> redis/monitoring은 EC2 유지 또는 별도 관리형 서비스 전환
```
