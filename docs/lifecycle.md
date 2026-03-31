# Lifecycle

이 문서는 `contract -> service` 흐름을 기준으로 인터페이스 변경이 어떻게 진행되어야 하는지 정의한다.

## 기본 원칙
1. 인터페이스 Source of Truth는 `contract` 레포다.
2. 구현 Source of Truth는 각 서비스 레포다.
3. 인터페이스 변경은 구현보다 먼저 계약을 갱신한다.
4. 서비스 레포는 contract SHA를 기준으로 동기화한다.

## 변경 순서
### 1) 요구사항 정의
- 브라우저/비브라우저
- 라우트/헤더
- 인증/보안
- 캐시
- 응답/에러
- 환경변수/OpenAPI

### 2) contract 갱신
- 관련 문서를 먼저 수정한다.
- OpenAPI가 있으면 함께 수정한다.
- `CONTRACT_SYNC.md`를 갱신한다.

### 3) contract 검증
- 문서 링크와 표가 깨지지 않는지 확인한다.
- breaking change면 버전 정책을 확인한다.
- 필요하면 adoption matrix를 갱신한다.

### 4) service 반영
- 각 서비스 레포의 구현을 contract에 맞춘다.
- 서비스 레포의 `CONTRACT_SYNC.md`에 contract SHA를 기록한다.
- 서비스별 테스트와 스모크를 수행한다.

### 5) 머지 순서
- contract PR을 먼저 머지한다.
- 그 다음 서비스 PR을 머지한다.

## Gateway 기준 예시
- 인증 채널 정책 변경
  - `contracts/gateway/auth.md`
  - `contracts/gateway/auth-proxy.md`
  - `contracts/common/security.md`
  - `contracts/auth/README.md`
  - `contracts/auth/api.md`
  - `contracts/auth/security.md`
  - `contracts/user/README.md`
  - `contracts/user/api.md`
  - `contracts/user/security.md`
  - `Api-gateway-server` 구현 반영
- 헤더 재주입 변경
  - `contracts/common/headers.md`
  - `contracts/gateway/security.md`
  - `Api-gateway-server` 구현 반영
- 캐시 정책 변경
  - `contracts/gateway/cache.md`
  - `contracts/gateway/env.md`
  - `Api-gateway-server` 구현 반영

## 자동화 연결
- 서비스 PR은 contract 영향 여부를 검사한다.
- contract PR 머지 후에는 서비스 레포 동기화 PR을 별도로 생성할 수 있다.
- 자동화는 검증과 제안을 담당하고, 기준 확정은 사람 리뷰가 담당한다.
