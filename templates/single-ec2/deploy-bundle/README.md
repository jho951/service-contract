# Single EC2 Deploy Bundle

이 디렉터리는 앱 레포를 EC2에 clone하지 않고, ECR 이미지와 배포용 manifest만으로 단일 EC2를 올리기 위한 self-contained 번들이다.

구성:

- `docker-compose.backend.yml`: backend 7개와 내부 DB/Redis/monitoring 정의
- `docker-compose.frontend.yml`: `editor-page`, `explain-page` 정의
- `.env.backend.example`: backend/monitoring 변수 예시
- `.env.frontend.example`: frontend 변수 예시
- `config/`: MySQL 초기화와 설정 파일
- `scripts/deploy-stack.sh`: 전체 또는 서비스 단위 pull/up/down/ps/logs 스크립트
- `scripts/cleanup-old-clones.sh`: `/opt/services` 아래 예전 clone 디렉토리 제거 스크립트
- `scripts/bootstrap-ec2.sh`: EC2에서 `/opt/deploy`에 deploy bundle을 설치하는 스크립트

## 목적

이 번들은 아래 상황을 전제로 한다.

1. CI/CD는 이미 ECR에 이미지를 push한다.
2. EC2는 이미지를 pull해서 실행만 한다.
3. EC2에는 앱 레포 전체를 둘 필요가 없다.
4. Nginx는 [../nginx.single-ec2.conf.example](../nginx.single-ec2.conf.example) 기준으로 별도 적용한다.

## 권장 배치

```text
/opt/deploy/
  docker-compose.backend.yml
  docker-compose.frontend.yml
  .env.backend
  .env.frontend
  config/
  scripts/
  nginx.single-ec2.conf.example
```

## 사용 순서

1. 이 디렉터리를 EC2의 `/opt/deploy`로 복사한다.
2. `.env.backend.example`을 `.env.backend`로 복사해 실제 값으로 채운다.
3. `.env.frontend.example`을 `.env.frontend`로 복사해 실제 값으로 채운다.
4. 기존 `/opt/services` clone 디렉터리를 정리하려면 `scripts/cleanup-old-clones.sh`를 실행한다.
5. `scripts/deploy-stack.sh up`으로 전체 스택을 실행한다.
6. 운영 중 단일 서비스만 갱신할 때는 `scripts/deploy-stack.sh up <service-name>`을 사용한다.
7. Nginx 설정은 `../nginx.single-ec2.conf.example`을 적용한다.

CI/CD 규칙:

- 자동 배포는 항상 `/opt/deploy`에서 `./scripts/deploy-stack.sh up <service-name>`만 호출한다.
- service repo workflow는 `contract.lock.yml`로 fetch한 `.contract/templates/single-ec2/deploy-bundle/`을 먼저 `/opt/deploy`에 동기화한 뒤 같은 경로의 스크립트를 호출한다.
- workflow에서 전체 `./scripts/deploy-stack.sh up`를 호출하지 않는다.
- `<service-name>`은 repo 기준 alias도 받는다. 예: `gateway-service`, `auth-service`, `user-service`, `authz-service`, `editor-service`, `redis-service`, `monitoring-service`.
- `gateway-service`는 downstream health에 묶여 기동이 막히지 않도록 compose `depends_on`으로 다른 app service를 강제하지 않는다. upstream 장애는 runtime `502/504`로 처리한다.

EC2에서 바로 bundle을 받으려면:

```bash
git clone https://github.com/jho951/service-contract.git /tmp/service-contract
/tmp/service-contract/templates/single-ec2/deploy-bundle/scripts/bootstrap-ec2.sh /opt/deploy
rm -rf /tmp/service-contract
```

## 예시

```bash
cd /opt/deploy
cp .env.backend.example .env.backend
cp .env.frontend.example .env.frontend
vi .env.backend
vi .env.frontend

FORCE=true ./scripts/cleanup-old-clones.sh /opt/services
./scripts/deploy-stack.sh up
```

서비스 단건 반영 예시:

```bash
cd /opt/deploy
./scripts/deploy-stack.sh up gateway-service
./scripts/deploy-stack.sh up redis-service
./scripts/deploy-stack.sh up monitoring-service
./scripts/deploy-stack.sh pull grafana
./scripts/deploy-stack.sh ps gateway-service
```

## 주의

- 이 번들은 앱 레포 source code 없이 동작하도록 구성돼 있다.
- 실제 배포 단위는 Git이 아니라 ECR image다.
- `editor-page`, `explain-page`는 외부에서 직접 공개하지 않고 `127.0.0.1`에 bind한 뒤 Nginx로 프록시한다.
- backend 서비스는 host publish 없이 Docker network alias로만 통신한다.
- `logs`는 backend/frontend 혼합 타깃을 한 번에 tail하지 않는다. 필요하면 `./scripts/deploy-stack.sh logs gateway-service`처럼 나눠서 실행한다.
- `.env.backend.example`의 `AUTH_MYSQL_IMAGE`, `USER_MYSQL_IMAGE`, `EDITOR_MYSQL_IMAGE`, `REDIS_EXPORTER_IMAGE`는 기본값이 Docker Hub 기준이다. 운영 안정성을 높이려면 ECR mirror 이미지로 바꿔 두는 편이 낫다.
- `user-mysql`은 빈 volume으로 처음 올라올 때 `users`, `user_social_accounts` baseline schema를 자동 초기화한다. 기존 volume을 재사용하는 경우 init SQL은 다시 실행되지 않으므로, 스키마 누락이면 `config/user-mysql/user-schema.sql`을 수동 적용해야 한다.
