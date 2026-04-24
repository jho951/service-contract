# CI/CD Contract

CI/CD는 모든 repository가 같은 단계 이름과 같은 실패 기준을 사용한다.
repo별 차이는 [registry/repositories.yml](../registry/repositories.yml)의 `ci` / `cd` profile에서만 override한다.

## CI Stages
| Stage | Required | Purpose |
| --- | --- | --- |
| contract-lock | yes | `contract.lock.yml`의 repo/ref/commit/consumes 검증 |
| setup-runtime | yes | Java, Node, Docker/Compose 같은 runtime 준비 |
| test | yes | unit/integration test |
| build | yes | bootJar, npm build, compose build 같은 artifact 생성 |
| image | deployable only | Docker image build/push |

## CD Stages
| Stage | Required | Purpose |
| --- | --- | --- |
| deploy-gate | yes | protected branch, tag, manual approval 확인 |
| image | deployable only | Docker image build/push 및 immutable tag 생성 |
| deploy | deployable only | EC2 compose, static hosting, package publish |
| health-check | service only | health endpoint 또는 runtime ping 확인 |
| smoke-test | yes | 배포 후 최소 기능 검증 |

## Rules
- `contract-lock`은 모든 repo에서 첫 번째 job으로 실행한다.
- `test`와 `build`는 contract 검증이 실패하면 실행하지 않는다.
- production deploy는 protected branch 또는 tag에서만 수행한다.
- service-specific command는 workflow에 직접 흩뿌리지 않고 `contract.lock.yml`과 `registry/repositories.yml`에 기록한다.
- 운영 배포용 Compose는 `build:` 대신 `image:`만 사용한다.
- build 설정과 private package 인증은 `docker/compose.build.yml` 또는 CI의 `docker build` 단계에만 둔다.
- 운영/실행용 Compose 파일은 image pull만 담당하고, build secret을 포함하지 않는다.
- 운영 이미지는 Amazon ECR repository를 기본으로 사용한다.
- 단일 이미지 서비스의 repository 이름은 `${deploy_environment}-${service_name}` 형식으로 통일한다.
- 다중 이미지 서비스는 `${deploy_environment}-${service_name}-<component>` suffix를 사용한다.
- 실제 배포 태그는 `${GITHUB_SHA}`를 기본 immutable tag로 사용한다.
- `latest` 태그는 `main` 또는 `master`에서만 추가 발행하고, deploy 대상 태그로 직접 사용하지 않는다.
- EC2 또는 원격 Docker host는 CI가 만든 이미지를 `docker compose pull [service...] && docker compose up -d [service...]` 또는 동등한 서비스 단위 pull/up 방식으로 반영한다.
- 전체 스택 초기 기동이 아니라 서비스 단건 CD라면 대상 서비스만 지정해서 반영하는 것을 우선한다.
- private repository 접근 토큰과 key는 CI 서버 또는 로컬 build 환경에만 두고, production runtime에는 주입하지 않는다.
- image-only EC2 배포를 쓰는 repo는 저장소 안에 `deploy/ec2` 산출물을 둔다.
- `deploy/ec2`에는 최소한 아래 파일을 둔다.
  - `docker-compose.yml`
  - `.env.production.example`
  - 필요 시 host Nginx example
  - 간단한 `README.md`
- CD workflow의 compose validation은 가능하면 실제 운영 실행 파일인 `deploy/ec2/docker-compose.yml`을 기준으로 수행한다.
- frontend page와 gateway는 운영에서 host Nginx reverse proxy를 기본으로 하고, 앱 컨테이너는 `127.0.0.1` bind를 기본값으로 둔다.
