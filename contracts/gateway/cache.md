# Gateway Cache

## 목적
Gateway가 인증 검증 비용을 줄이기 위해 사용하는 캐시와 요청 제어를 정리한다.

## L1 캐시
- 클래스: `LocalSessionCache`
- 위치: Gateway 인스턴스 메모리
- 역할: 인증 성공 결과를 짧은 TTL로 보관
- 특징:
  - 단일 인스턴스 범위
  - `ConcurrentHashMap` 기반
  - TTL 초과 시 자동 폐기

## L2 캐시
- 클래스: `RedisSessionCache`
- 위치: Redis
- 역할: 인증 성공 결과를 인스턴스 간 공유
- 특징:
  - 인증 성공 결과만 저장
  - `gateway:session:` 프리픽스를 사용
  - 토큰 해시가 아니라 session cache key를 사용

## 캐시 대상
- Bearer 토큰 기반 검증 결과
- auth-service 응답으로 확인된 `AuthResult`
- authz-service 응답으로 확인된 관리자 경로 판정 결과

## 캐시 흐름
1. L1 캐시를 먼저 조회한다.
2. 실패하면 L2 Redis 캐시를 조회한다.
3. 둘 다 실패하면 JWT 검증과 auth-service 세션 검증을 수행한다.
4. `ADMIN` 라우트면 authz-service 판정을 수행한다.
5. 검증 성공 결과를 L1/L2에 다시 저장한다.

## Authz Cache
- 클래스: `RedisPermissionCache`
- 위치: Redis
- 역할: `ADMIN` 라우트의 허용/거부 결과를 짧은 TTL로 보관
- 프리픽스: `gateway:admin-permission:`
- 비고: authz-service 오류나 타임아웃은 캐시로 완화하지 않고 fail-closed를 유지한다.

## Redis Contract
- 중앙 Redis 자체 계약은 [Redis Contract](../redis/README.md)를 따른다.
- Gateway는 `gateway:session:`과 `gateway:admin-permission:` prefix만 사용한다.

## 요청 제어
- 로그인 경로는 고정 윈도우 rate limiter를 사용한다.
- 키는 client IP이다.
- 기본값은 분당 20회다.

## 운영 메모
- L1 TTL과 L2 TTL은 별도로 조정할 수 있다.
- Redis 장애 시 Gateway는 로컬 로그만 남기고 인증 경로를 계속 진행한다.
- authz-service 장애 시 Gateway는 관리자 경로를 fail-closed로 처리한다.
