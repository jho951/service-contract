# Implementation Rollup 2026-04-24

이 문서는 2026-04-24 기준으로 실제 구현 레포에 반영한 변경을 한 번에 정리한다.

## 1. 운영 이미지 정책 통일

모든 운영 배포는 아래 규칙으로 통일했다.

- registry: Amazon ECR
- repository naming: `${deploy_environment}-${service_name}`
- monitoring component naming: `${deploy_environment}-monitoring-service-<component>`
- immutable deploy tag: `${GITHUB_SHA}`
- floating tag: `latest`는 `main` 또는 `master`에서만 추가 발행
- 운영 compose: `build:` 대신 `image:` 사용
- 운영 반영 방식: `docker compose pull && docker compose up -d`

## 2. Build/Run 분리

앱 서비스 `gateway-service`, `auth-service`, `user-service`, `authz-service`, `editor-service`는 Compose를 두 계층으로 분리했다.

- 실행 전용:
  - `docker/compose.yml`
  - `docker/dev/compose.yml`
  - `docker/prod/compose.yml`
- 빌드 전용:
  - `docker/compose.build.yml`

원칙:

- `dev`는 `compose.build.yml`을 추가로 겹쳐 local build를 허용한다.
- `prod`는 실행 전용 compose만 사용하고 build secret을 받지 않는다.
- private package 접근용 `GH_TOKEN`, `GITHUB_ACTOR`는 build 단계에만 사용한다.

## 3. 서비스별 구현 변경

### gateway-service

- prod compose를 `GATEWAY_IMAGE` 기반 image-only 구조로 고정
- base compose의 runtime 기본 이미지를 `gateway-service:dev`로 정리
- `docker/compose.build.yml` 추가
- `scripts/run.docker.sh`를 dev build/prod pull 구조로 분리
- Docker 운영 문서를 ECR 기준으로 정리

### auth-service

- base compose를 image-first로 전환
- dev build를 `docker/compose.build.yml`로 분리
- prod compose를 `AUTH_SERVICE_IMAGE` 기반 image-only로 유지
- `scripts/run.docker.sh`를 dev build/prod pull 구조로 정리
- Docker 문서를 ECR/image-only 기준으로 갱신

### user-service

- base compose를 image-first로 전환
- dev build를 `docker/compose.build.yml`로 분리
- prod compose를 `USER_SERVICE_IMAGE` 기반 image-only로 고정
- `scripts/run.docker.sh`에서 prod build 금지
- Docker 문서를 build/run 분리 기준으로 갱신

### authz-service

- base compose를 image-first로 전환
- dev build를 `docker/compose.build.yml`로 분리
- prod compose를 `AUTHZ_SERVICE_IMAGE` 기반 image-only로 고정
- `scripts/run.docker.sh`에서 prod build 금지
- CI/구현 문서를 ECR 기준으로 갱신

### editor-service

- prod compose를 `EDITOR_SERVICE_IMAGE` 기반 image-only로 고정
- dev build를 `docker/compose.build.yml`로 분리
- `scripts/run.docker.sh`에서 prod build 금지
- README에 운영 pull 구조와 dev build 분리 원칙 반영

### redis-service

- prod compose를 `REDIS_IMAGE` 기반 image-only로 전환
- exporter 이미지를 `REDIS_EXPORTER_IMAGE`로 외부 제어 가능하게 정리
- CD workflow를 Amazon ECR push 기준으로 전환
- `contract.lock.yml`의 image registry를 ECR로 수정

### monitoring-service

- prod compose를 `PROMETHEUS_IMAGE`, `GRAFANA_IMAGE`, `LOKI_IMAGE`, `PROMTAIL_IMAGE` 기반 image-only로 전환
- CD workflow를 Amazon ECR push 기준으로 전환
- README와 운영 문서를 ECR/image-only 기준으로 갱신
- `contract.lock.yml`의 image registry를 ECR로 수정

### editor-page

- prod compose를 `EDITOR_PAGE_IMAGE` 기반 image-only로 전환
- `docker/docker-compose.build.yml`을 추가해 build 전용 경로를 분리
- `scripts/run.docker.sh`를 dev build/prod pull 구조로 정리
- `ci.yml`, `cd.yml`을 추가해 ECR build/push와 remote pull 배포를 표준화

### explain-page

- prod compose를 `EXPLAIN_PAGE_IMAGE` 기반 image-only로 전환
- `docker/docker-compose.build.yml`을 추가해 Next.js standalone build를 CI 전용으로 분리
- `scripts/run.docker.sh`를 dev build/prod pull 구조로 정리
- `cd.yml`을 추가해 ECR build/push와 remote pull 배포를 표준화

## 4. 공통 문서/템플릿 변경

- [shared/ci-cd.md](./ci-cd.md): image stage, ECR naming, immutable tag, build/run 분리 규칙 추가
- [shared/single-ec2-deployment.md](./single-ec2-deployment.md): single EC2 운영에서도 image-only 배포 규칙 반영
- [shared/single-ec2-edge-routing.md](./single-ec2-edge-routing.md): backend 7개와 frontend 2개를 함께 노출하는 최종 포트/도메인/Nginx 기준 추가
- [templates/single-ec2/README.md](../templates/single-ec2/README.md): ECR image URI 주입 기준 반영
- [templates/single-ec2/nginx.single-ec2.conf.example](../templates/single-ec2/nginx.single-ec2.conf.example): EC2 reverse proxy 예시 추가
- [templates/single-ec2/env/](../templates/single-ec2/env/): 서비스별 `*_IMAGE` 변수 추가
- [templates/contract-lock-template.yml](../templates/contract-lock-template.yml): 기본 image registry를 ECR로 변경
- [templates/github-actions-contract-check.yml](../templates/github-actions-contract-check.yml): ECR login 예시로 변경
- [registry/repositories.yml](../registry/repositories.yml): 기본 CD profile의 image registry를 ECR로 정리

## 5. Repo별 `deploy/ec2` bundle 정리

실제 구현 repo에는 EC2에 source를 clone하지 않고도 배포할 수 있도록 `deploy/ec2` 산출물을 두는 방향으로 정리했다.

대상:

- `auth-service`
- `authz-service`
- `editor-service`
- `gateway-service`
- `monitoring-service`
- `redis-service`
- `user-service`
- `editor-page`
- `explain-page`

기본 bundle 구성:

- `docker-compose.yml`
- `.env.production.example`
- 필요 시 `nginx/*.conf.example`
- `README.md`

추가 메모:

- `auth-service`와 `user-service`는 MySQL 보조 설정 파일까지 bundle에 포함한다.
- `editor-page`, `explain-page`, `gateway-service`는 host Nginx reverse proxy 기준 example을 함께 둔다.
- `monitoring-service`는 Grafana 노출이 필요한 경우를 대비해 host Nginx example을 함께 둔다.
- `redis-service`, `monitoring-service`, `editor-page`, `explain-page`의 CD workflow는 가능하면 `deploy/ec2/docker-compose.yml` 기준 validation으로 맞춘다.

## 6. Editor-page 최근 UI/UX 및 품질 게이트 정리

`editor-page` 실제 구현에는 아래 변경이 함께 반영됐다.

- 커스텀 `context menu`, `confirm`, `toast` host 도입
- 블록 편집기 좌측 rail SVG 아이콘화와 context menu 정리
- `Cmd/Ctrl + S` 제거, 텍스트 입력 중 `Cmd/Ctrl + A` native select-all 유지
- 홈/휴지통 목록 상단을 공용 `DocumentsPageHeader`로 통합
- 홈/휴지통 목록의 카드/리스트 토글을 공통 디자인으로 정리
- 휴지통 목록에서 우클릭 기반 `복구`, `완전 삭제` 처리
- LNB 우클릭 중심 조작과 drag-and-drop 이동 추가
- 모바일에서 로고 기반 전체 화면 LNB overlay 도입
- `not-found`를 explain-page 스타일 404로 정리
- 품질 게이트 기준으로는 `eslint.config.js`, `.eslintignore`, `npm run lint`, `npm run typecheck`가 현재 존재한다.
- 반면 Husky pre-commit hook과 `lint-staged`는 아직 구현 repo에 없다.

## 7. 남은 운영 작업

구현은 끝났고 실제 배포 전에는 아래만 채우면 된다.

- Amazon ECR repository 생성
- GitHub Actions secret/variable 등록
- 배포 대상의 ECR pull 권한 부여
- 서비스별 `.env.prod`에 실제 이미지 URI와 시크릿 값 입력
- CI/CD 실행 후 health check
