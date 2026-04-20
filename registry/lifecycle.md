# Lifecycle

## 기본 원칙
1. 인터페이스 Source of Truth는 `contract` 레포다.
2. 구현 Source of Truth는 각 서비스 레포다.
3. 인터페이스 변경은 구현보다 먼저 계약을 갱신한다.
4. 서비스 레포는 `contract.lock.yml`의 contract ref/SHA를 기준으로 검증한다.

## 변경 순서
### 1) 요구사항 정의
- 브라우저/비브라우저
- 라우트/헤더
- 인증/보안
- 캐시
- 응답/에러
- 환경변수/OpenAPI
- 권한/기능/정책 판단은 `shared/decision-criteria.md`를 먼저 본다.

### 2) contract 갱신
- 관련 문서를 먼저 수정한다.
- OpenAPI가 있으면 함께 수정한다.
- breaking change면 새 버전 또는 migration 문서를 함께 준비한다.

### 3) contract 검증
- 문서 링크와 표가 깨지지 않는지 확인한다.
- breaking change면 버전 정책을 확인한다.
- 필요하면 adoption matrix를 갱신한다.

### 4) service 반영
- 각 서비스 레포의 구현을 contract에 맞춘다.
- 서비스 레포의 `contract.lock.yml`에 contract ref/SHA를 기록한다.
- 서비스별 테스트, 스모크, CI 계약 검증을 수행한다.

### 5) 머지 순서
- contract PR을 먼저 머지한다.
- 그 다음 서비스 PR을 머지한다.

## Gateway 기준 예시
- 인증 채널 정책 변경
  - `repositories/gateway-service/auth.md`
  - `repositories/gateway-service/auth-proxy.md`
  - `shared/security.md`
  - `repositories/auth-service/README.md`
  - `repositories/auth-service/api.md`
  - `repositories/auth-service/security.md`
  - `repositories/user-service/README.md`
  - `repositories/user-service/api.md`
  - `repositories/user-service/security.md`
  - `gateway-service` 구현 반영
- 헤더 재주입 변경
  - `shared/headers.md`
  - `repositories/gateway-service/security.md`
  - `gateway-service` 구현 반영
- 캐시 정책 변경
  - `repositories/gateway-service/cache.md`
  - `repositories/gateway-service/env.md`
  - `gateway-service` 구현 반영

## 공통 판단 기준
- 새 권한이나 기능을 추가할 때는 서비스별 문서보다 먼저 `shared/decision-criteria.md`를 확인한다.
- `role`, `condition`, token scope, cache invalidation, final enforcement를 같은 판단 축으로 본다.

## 자동화 연결
- 서비스 PR은 contract 영향 여부를 검사한다.
- contract PR 머지 후에는 서비스 레포의 `contract.lock.yml` 갱신 PR을 별도로 생성할 수 있다.
- 자동화는 검증과 제안을 담당하고, 기준 확정은 사람 리뷰가 담당한다.

## 문제 해결
- 자주 겪는 기동/동기화 이슈는 [Troubleshooting](troubleshooting.md)를 먼저 본다.
