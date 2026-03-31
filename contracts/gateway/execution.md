# 실행

MSA 앞단에서 외부 요청을 받아 인증과 라우팅을 정규화하는 진입점이다.

기본 접속 포트는 `http://localhost:8080` 이다.

## 요구 사항
- Java 17
- Docker
- Docker Compose

## 사전 준비
실행 전에 아래 서비스가 먼저 기동되어 있어야 한다.

- `auth-service`
- `authz-service`
- `user-service`
- `block-service`
- `redis`

Gateway 전용 환경변수는 [Gateway Environment Contract](env.md)를 따른다.
특히 인증 검증을 운영 수준으로 맞추려면 다음 값이 필요하다.

- `AUTH_JWT_VERIFY_ENABLED=true`
- `PERMISSION_SERVICE_URL=http://authz-service:8084`
- `PERMISSION_ADMIN_VERIFY_URL=http://authz-service:8084/permissions/internal/admin/verify`

## Docker 구성
환경별로 Docker Compose 파일을 분리해서 사용한다.

- dev: `docker/docker-compose.dev.yml`
- prod: `docker/docker-compose.prod.yml`

실행 스크립트는 환경에 맞는 Compose 구성을 사용해 Gateway를 올린다.

## 실행 방법
### dev
```bash
bash scripts/run.docker.sh dev
```

### prod
```bash
bash scripts/run.docker.sh prod
```

## 기동 확인
Gateway가 정상적으로 떠 있는지 아래 엔드포인트로 확인한다.

- `GET /v1/health`
- `GET /v1/ready`

```bash
curl -i http://localhost:8080/v1/health
curl -i http://localhost:8080/v1/ready
```

## 주의
- Gateway만 단독으로 띄워도 시작은 가능하지만, 실제 라우팅/인증 성공 여부는 upstream 서비스 상태에 따라 달라진다.
- `AUTH_JWT_VERIFY_ENABLED=true`인 운영 환경에서는 auth-service 토큰 검증 설정이 Gateway와 일치해야 한다.
- `authz-service`가 없으면 `ADMIN` 라우트는 fail-closed로 거부될 수 있다.
