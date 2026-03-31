# Contract Repository

MSA 간 인터페이스(라우트, 헤더, 보안, 에러, 환경변수, OpenAPI)의 단일 기준(Source of Contract) 저장소입니다.

## 목적
- 서비스별 코드 Source of Truth는 각 서비스 레포에 유지
- 서비스 간 인터페이스 Source of Truth는 이 레포에서 단일 관리
- 계약 드리프트 방지(개별 레포 문서와 실제 동작 불일치 최소화)

## 적용 대상
### 백엔드 서비스
- `Api-gateway-server` (main)
- `Auth-server` (main)
- `Authz-server` (main)
- `User-server` (main)
- `Redis-server` (main)
- `Block-server` (main)

### 프론트엔드 페이지
- `Editor-page` (main)
- `Explain-page` (main)

## 문서 인덱스
- [Common](contracts/common/README.md)
- [Auth](contracts/auth/README.md)
- [Authz](contracts/authz/README.md)
- [User](contracts/user/README.md)
- [Redis](contracts/redis/README.md)
- [Gateway](contracts/gateway/README.md)
- [Editor](contracts/editor/README.md)

## 빠른 실행

```bash
# 백엔드 서비스 레포 동기화 + 네트워크 준비
./scripts/msa-stack.sh init
```
```bash
# 백엔드 MSA compose up
./scripts/msa-stack.sh up
```
```bash
# 상태 확인
./scripts/msa-stack.sh ps
```

- 상세: [Stack Orchestration](docs/stack-orchestration.md)

## 원칙
1. Breaking change는 반드시 계약 버전 증가(`v2+`) 후 반영
2. 구현 변경보다 계약 변경 PR을 먼저 머지
3. Gateway는 외부 계약(`/v1/**`)의 유일한 노출 지점
4. 내부 서비스는 `/v1` 없는 내부 경로만 소유

## Contract Sync
- 이 레포의 동기화 기준 파일은 루트 [CONTRACT_SYNC.md](CONTRACT_SYNC.md) 이다.
- 서비스 레포도 동일한 형식의 `CONTRACT_SYNC.md`를 유지한다.
- 템플릿은 [docs/examples/contract-sync-template.md](docs/examples/contract-sync-template.md) 를 참고한다.
