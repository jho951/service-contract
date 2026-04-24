# Single EC2 Templates

이 디렉터리는 단일 EC2 `m7i-flex.large` 배포를 바로 시작할 수 있게 하는 템플릿 모음이다.

## 포함 파일

| 경로 | 역할 |
| --- | --- |
| [user_data.sh.tftpl](user_data.sh.tftpl) | EC2 부팅 시 Docker, Git, shared network, 공용 디렉터리를 준비하는 bootstrap 스크립트 |
| [user_data.full-stack.sh.tftpl](user_data.full-stack.sh.tftpl) | EC2 부팅 시 7개 서비스 runtime repo, env 생성, 전체 스택 자동 배포까지 수행하는 완성형 user data |
| [user_data.full-stack.vars.example.md](user_data.full-stack.vars.example.md) | full-stack user data 변수 채우는 방법과 base64 env 전달 예시 |
| [full-stack.user-data.vars.example.env](full-stack.user-data.vars.example.env) | 완성형 user data 렌더링용 실제 vars 파일 형식 예시 |
| [docker-compose.single-ec2.service.override.yml](docker-compose.single-ec2.service.override.yml) | backend service용 shared network/restart 정책 템플릿 |
| [docker-compose.single-ec2.gateway-public.override.yml](docker-compose.single-ec2.gateway-public.override.yml) | gateway 외부 공개용 override 템플릿 |
| [docker-compose.single-ec2.redis-alias.override.yml](docker-compose.single-ec2.redis-alias.override.yml) | Redis shared-network alias를 `redis`로 고정하는 override 템플릿 |
| [deploy-bundle/](deploy-bundle/) | 앱 레포 clone 없이 `compose + env + nginx`만으로 단일 EC2를 올리는 self-contained 배포 번들 |
| [nginx.single-ec2.conf.example](nginx.single-ec2.conf.example) | `api`, `editor`, `explain`, `grafana` 도메인을 내부 포트로 라우팅하는 Nginx 예시 |
| [env/](env/) | 서비스별 `.env.prod` 예시 템플릿 |
| [overrides/](overrides/) | 실제 서비스 레포 compose 구조에 맞춘 concrete override 파일 |
| [scripts/](scripts/) | 실제 서비스 레포를 순서대로 올리는 단일 EC2 실행 스크립트 |

## 기본 사용 순서

1. 수동 모드면 `user_data.sh.tftpl`을 적용한다.
2. 자동 모드면 `user_data.full-stack.sh.tftpl`을 적용한다.
3. 자동 모드에서는 `user_data.full-stack.vars.example.md`를 보고 repo URL, ref, base64 env 값을 채운다.
4. 자동 모드에서 실제 렌더링은 `scripts/render-full-stack-user-data.sh`를 사용한다.
5. 수동 모드에서는 각 서비스 repo `.env.prod`를 준비하고 ECR image URI를 채운다.
6. `scripts/deploy-single-ec2-service.sh` 또는 `scripts/deploy-single-ec2-stack.sh`로 실행한다.
7. `service-backbone-shared` network에 모든 서비스를 붙인다.
8. 전체 초기 기동은 `redis -> auth -> user -> authz -> editor -> gateway` 순으로 이미지를 pull한 뒤 실행한다.
9. 운영 중 단일 서비스 반영은 `scripts/deploy-single-ec2-service.sh <service-name> <repo-dir> up`처럼 대상 서비스만 갱신한다.
10. 외부 공개는 `nginx.single-ec2.conf.example` 또는 [../../shared/single-ec2-edge-routing.md](../../shared/single-ec2-edge-routing.md) 기준으로 Nginx에 붙인다.
11. 현재 `full-stack user_data`와 배포 스크립트는 backend 7개를 기본 자동화 범위로 보고, `editor-page`, `explain-page`, Nginx는 후속 단계에서 별도로 반영한다.
12. 앱 레포를 EC2에 clone하지 않으려면 `deploy-bundle/README.md`의 bundle 방식을 우선 사용한다.

## 실제 실행

단일 서비스:

```bash
./templates/single-ec2/scripts/deploy-single-ec2-service.sh \
  auth-service \
  /opt/services/auth-service \
  up
```

전체 스택:

```bash
SERVICES_ROOT=/opt/services \
./templates/single-ec2/scripts/deploy-single-ec2-stack.sh up
```

Monitoring까지 포함:

```bash
SERVICES_ROOT=/opt/services INCLUDE_MONITORING=true \
./templates/single-ec2/scripts/deploy-single-ec2-stack.sh up
```

## 완전 자동 배포

EC2가 뜨자마자 7개 서비스까지 자동으로 올리려면 [user_data.full-stack.sh.tftpl](user_data.full-stack.sh.tftpl)을 사용한다.

이 템플릿은 다음을 한 번에 수행한다.

1. Docker/Git/bootstrap 준비
2. contract repo clone
3. 7개 서비스 runtime repo clone
4. base64로 전달된 `.env.prod` 파일 생성
5. 서비스별 `pull/up`를 순서대로 수행하는 `deploy-single-ec2-stack.sh up` 실행

변수 형식은 [user_data.full-stack.vars.example.md](user_data.full-stack.vars.example.md)를 따른다.

실제 렌더링 예시:

```bash
./templates/single-ec2/scripts/render-full-stack-user-data.sh \
  ./templates/single-ec2/full-stack.user-data.vars.example.env \
  /tmp/full-stack.user-data.sh
```

## compose 예시

backend service:

```bash
docker compose \
  -f docker/prod/compose.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.service.override.yml \
  pull && \
docker compose \
  -f docker/prod/compose.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.service.override.yml \
  up -d
```

gateway:

```bash
docker compose \
  -f docker/prod/compose.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.service.override.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.gateway-public.override.yml \
  pull && \
docker compose \
  -f docker/prod/compose.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.service.override.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.gateway-public.override.yml \
  up -d
```

redis:

```bash
docker compose \
  -f docker/prod/compose.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.service.override.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.redis-alias.override.yml \
  pull && \
docker compose \
  -f docker/prod/compose.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.service.override.yml \
  -f /opt/services/shared/overrides/docker-compose.single-ec2.redis-alias.override.yml \
  up -d
```

## 주의

- 실제 compose service key가 repo마다 다를 수 있으므로 `<service-name>` placeholder는 각 repo의 canonical service key로 치환한다.
- 운영 배포에서는 source build를 하지 않고, `.env.prod`에 채운 ECR image URI만 pull한다.
- `mysql`, `redis_exporter` 같은 서드파티 운영 이미지는 env 변수로 override 가능하게 두고, 운영에서는 가능하면 ECR mirror를 권장한다.
- gateway만 host port를 외부에 publish한다.
- backend service와 Redis는 host publish 없이 Docker network alias로만 통신하는 것을 기본값으로 둔다.
- concrete 실행은 `overrides/`와 `scripts/`를 우선 사용하고, generic override는 참고용으로만 둔다.
