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
| deploy | deployable only | EC2 compose, static hosting, package publish |
| health-check | service only | health endpoint 또는 runtime ping 확인 |
| smoke-test | yes | 배포 후 최소 기능 검증 |

## Rules
- `contract-lock`은 모든 repo에서 첫 번째 job으로 실행한다.
- `test`와 `build`는 contract 검증이 실패하면 실행하지 않는다.
- production deploy는 protected branch 또는 tag에서만 수행한다.
- service-specific command는 workflow에 직접 흩뿌리지 않고 `contract.lock.yml`과 `registry/repositories.yml`에 기록한다.
