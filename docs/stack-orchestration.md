# Stack Orchestration

`contract` 레포에서 전체 MSA를 한 번에 기동/종료하는 스크립트입니다.

## Script
- `scripts/msa-stack.sh`

## Commands
```bash
# 레포 동기화 + shared network 준비
./scripts/msa-stack.sh init

# 전체 서비스 up
./scripts/msa-stack.sh up

# 상태 확인
./scripts/msa-stack.sh ps

# 전체 서비스 down
./scripts/msa-stack.sh down
```

## Defaults
- `MSA_HOME=$HOME/msa`
- `SHARED_SERVICE_NETWORK=service-backbone-shared`
- SoT branches:
  - gateway/auth/permission/user/redis: `main`
  - block: `dev`

## Notes
- 이 스크립트는 백엔드 MSA 스택만 기동합니다. `Editor-page`와 `Explain-page`는 별도 프론트엔드 레포에서 관리합니다.
- `Auth-server`는 `.env.dev`가 있으면 우선 사용하고, 없으면 fallback 기본값으로 기동을 시도합니다.
- `Authz-server`는 `./gradlew bootRun`으로 기동하며 기본 포트는 `8084`다.
- 단, OAuth/실운영 인증까지 포함한 정상 동작은 `contracts/common/env.md`와 `contracts/auth/README.md`의 필수값 설정이 필요합니다.
- 일부 서비스가 shared network에 기본 미조인인 경우, 스크립트가 `docker network connect --alias`로 보정합니다.
