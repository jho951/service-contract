# Authz Operations Contract

## Startup / Runtime
- Authz는 관리자 경로 인가 판정 기준 서비스다.
- 애플리케이션 실행은 `./gradlew bootRun`이다.
- 기본 포트는 `8084`다.
- `GET /health` 와 `GET /ready` 는 운영 확인용이다.

## Operational Flows
- 권한 판정 성공은 `200`, 거부는 `403`, 입력 오류는 `400`이다.
- `X-Request-Id`와 `X-Correlation-Id`가 없으면 서버가 생성할 수 있다.
- L1 인메모리 캐시와 L2 Redis 캐시를 사용한다.
- Redis 장애 시 판정 API는 DB fallback을 유지하고, readiness는 `DOWN`일 수 있다.

## Maintenance
- 역할과 권한 seed는 `permission-seed.sql` 기준으로 유지한다.
- 관리자 경로 규칙 변경은 Gateway와 함께 맞춘다.
- 운영 오류는 `PermissionBadRequestException`, `403`, `ready DOWN`부터 점검한다.

## Validation
- `./gradlew bootRun`
- `curl -i http://localhost:8084/health`
- `curl -i http://localhost:8084/ready`
- `curl -i -X POST http://localhost:8084/permissions/internal/admin/verify -H 'X-User-Id: admin-seed' -H 'X-Session-Id: session-seed' -H 'X-Original-Method: GET' -H 'X-Original-Path: /v1/admin/blocks' -H 'X-Request-Id: debug-req-1' -H 'X-Correlation-Id: debug-corr-1'`

## Notes
- 내부 엔드포인트는 Gateway 또는 내부 네트워크에서만 호출한다.
- 관리자 경로는 `/admin/**`와 `/v1/admin/**`를 모두 고려한다.
- `X-User-Role`은 운영 검증 입력으로 사용하지 않는다. role/permission은 Authz가 `X-User-Id` 기준으로 조회한다.
