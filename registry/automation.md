# Automation

이 문서는 contract 변경과 service 동기화를 자동화하는 방법을 정리한다.

## 목표
- 서비스 PR에서 contract 영향 변경 누락을 차단한다.
- contract 머지 후 서비스 레포의 `contract.lock.yml` 갱신 PR 생성을 자동화할 수 있도록 한다.

## 자동화 레벨
### 1) Guardrail
- 서비스 레포 PR에서 `contract.lock.yml`의 contract ref와 소비 계약 목록을 검사한다.
- 계약 영향이 있으면 머지 전에 실패시킨다.

### 2) Assist
- contract 레포 머지 후 서비스 레포에 동기화 PR을 자동 생성한다.
- PR 본문에 contract ref/SHA, 영향 영역, 검증 항목을 넣는다.

### 3) Full automation
- 서비스 레포를 직접 수정하는 대신, 동기화 PR만 자동으로 생성한다.
- merge는 사람이 한다.

## 계약 영향 감지 대상
서비스 코드 변경 파일을 보고 계약 영향 영역을 감지한다.
영향이 있으면 PR 내에서 `contract.lock.yml` 갱신 또는 CI 계약 검증이 있었는지 검사한다.
우선 지원 대상:
- `gateway`
- `auth`
- `authz`
- `user`
- `redis`
- `editor`
- `monitoring`
- `audit-log`

## 현재 적용 대상
2026-04-20 기준 guardrail은 다음 8개 로컬 레포에 반영한다.

| Target | Repo Path | Lock | Workflow |
| --- | --- | --- | --- |
| `gateway` | `services/gateway-service` | `contract.lock.yml` | `.github/workflows/contract-check.yml` |
| `auth` | `services/auth-service` | `contract.lock.yml` | `.github/workflows/contract-check.yml` |
| `authz` | `services/authz-service` | `contract.lock.yml` | `.github/workflows/contract-check.yml` |
| `user` | `services/user-service` | `contract.lock.yml` | `.github/workflows/contract-check.yml` |
| `editor` | `services/editor-service` | `contract.lock.yml` | `.github/workflows/contract-check.yml` |
| `redis` | `services/redis-service` | `contract.lock.yml` | `.github/workflows/contract-check.yml` |
| `monitoring` | `services/monitoring-service` | `contract.lock.yml` | `.github/workflows/contract-check.yml` |
| `audit-log` | `module/audit-log` | `contract.lock.yml` | `.github/workflows/contract-check.yml` |

## 공통 CI/CD Profile
공통 profile은 [repositories.yml](repositories.yml)에 둔다. 각 repo는 `ci`와 `cd` profile을 상속하고 필요한 port, health path, command만 override한다.

| Profile | 대상 | 기본 단계 |
| --- | --- | --- |
| `spring-boot` | gateway/auth/authz/user/editor service | contract lock, Java setup, Gradle test, bootJar, Docker image |
| `infra` | redis/monitoring runtime | contract lock, compose config, compose build, Docker image |
| `frontend` | Editor-page/Explain-page | contract lock, Node setup, npm test, npm build, Docker/static artifact |
| `module` | audit-log 같은 library/module | contract lock, Java setup, Gradle test/build, publish-on-tag |

CD profile은 `ec2-compose`, `frontend-static`, `library-publish`로 나누고, production deploy는 protected branch 또는 tag에서만 수행한다.

## 서비스 PR CI 예시
```yaml
name: service-ci

on:
  pull_request:
  push:
    branches:
      - main
      - master
      - dev

jobs:
  contract-lock:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Fetch base branch
        run: git fetch origin ${{ github.base_ref }} --depth=1

      - name: Validate contract lock
        env:
          SERVICE_NAME: gateway
        run: |
          test -f contract.lock.yml
          grep -q "repo: https://github.com/jho951/service-contract" contract.lock.yml
          grep -q "name: $SERVICE_NAME" contract.lock.yml
          grep -q "consumes:" contract.lock.yml

  test-build:
    needs: contract-lock
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"
          cache: gradle
      - run: ./gradlew clean test
      - run: ./gradlew bootJar
```

## contract.lock.yml 기준 검증
서비스 레포는 긴 동기화 문서 대신 작은 lock 파일을 둔다.

```yaml
contract:
  repo: https://github.com/jho951/service-contract
  ref: v2026.04.16
  commit: abc1234

service:
  name: auth
  branch: main
  role: backend-service
  consumes:
    - shared/headers.md
    - shared/errors.md
    - repositories/auth-service/**
    - artifacts/openapi/auth-service.v2.yaml

validation:
  contract_lock: true
  openapi: true
  schema: true
  routing: true
  headers: true
  errors: true
  security: true

ci:
  profile: spring-boot
  runtime: java
  java_version: "17"
  setup: gradle
  test_command: ./gradlew clean test
  build_command: ./gradlew bootJar
  docker: true

cd:
  profile: ec2-compose
  target: ec2
  strategy: docker-compose
  environments:
    - dev
    - prod
  image_registry: ghcr.io
  deploy_on: protected_branch
  health_check: true
  smoke_test: true
```

CI는 이 파일을 읽고 contract repo의 ref를 checkout한 뒤 서비스 코드와 OpenAPI/schema/header/error 계약을 비교한다.

## contract 머지 후 동기화 PR
1. `contract` 레포 main 머지를 감지한다.
2. 영향을 받는 서비스 레포를 결정한다.
3. 서비스 레포 checkout 후 `contract.lock.yml`의 ref/commit을 갱신한다.
4. 새 브랜치로 push한다.
5. 서비스 레포에 PR을 생성한다.

## 권장 워크플로
- `contract` 레포: 문서/OpenAPI 검증
- 서비스 레포: 영향 검사 + `contract.lock.yml` 기준 계약 검증
- 동기화 봇: contract ref/SHA 반영 PR 생성

## 실패 시 의미
- 계약 영향 변경이 있는데 서비스 레포 `contract.lock.yml`이 갱신되지 않았거나, 구현이 lock된 계약과 맞지 않음을 의미한다.
- 조치:
  1. `contract` 레포 문서/OpenAPI 먼저 갱신
  2. 서비스 레포 `contract.lock.yml`에 contract ref/SHA 반영
  3. CI 계약 검증 실패 항목을 구현 또는 계약 문서에 맞춰 수정

## 참고
- 서비스 레포의 README에는 `contract.lock.yml`을 기준 파일로 명시한다.
- 자세한 변경 흐름은 [Lifecycle](lifecycle.md)을 따른다.
