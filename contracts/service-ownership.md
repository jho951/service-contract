# Service Ownership

## Source of Truth
- `Api-gateway-server` (branch: `main`): 외부 라우팅, prefix strip, trusted header 재주입
- `Auth-server` (branch: `main`): 인증/인가 컨텍스트, SSO 세션/토큰
- `User-server` (branch: `main`): 사용자 마스터 데이터, 소셜 링크 소유권
- `Redis-server` (branch: `main`): 캐시/세션 저장 계층 운영 표준
- `Block-server` (branch: `dev`): 문서/워크스페이스 도메인

## 주의
- 코드 SoT는 위 각 서비스 레포
- 인터페이스 SoT는 본 `contract` 레포
