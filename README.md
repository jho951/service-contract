# Contract Repository

MSA 간 인터페이스(라우트, 헤더, 보안, 에러, 환경변수, OpenAPI)의 단일 기준(Source of Contract) 저장소입니다.

## 목적
- 서비스별 코드 Source of Truth는 각 서비스 레포에 유지
- 서비스 간 인터페이스 Source of Truth는 이 레포에서 단일 관리
- 계약 드리프트 방지(개별 레포 문서와 실제 동작 불일치 최소화)

## 적용 대상
- `Api-gateway-server` (main)
- `Auth-server` (main)
- `User-server` (main)
- `Redis-server` (main)
- `Block-server` (dev)

## 문서 인덱스
- [서비스 소유권](contracts/service-ownership.md)
- [라우팅 계약](contracts/routing.md)
- [헤더 계약](contracts/headers.md)
- [보안 계약](contracts/security.md)
- [에러 계약](contracts/errors.md)
- [환경변수 계약](contracts/env.md)
- [버전 정책](contracts/versioning.md)
- [변경 프로세스](contracts/change-process.md)
- [도입 매트릭스](contracts/adoption-matrix.md)
- [도입 플레이북](docs/adoption-playbook.md)
- OpenAPI
  - `contracts/openapi/gateway-edge.v1.yaml`
  - `contracts/openapi/user-service.v1.yaml`
  - `contracts/openapi/auth-service.v1.yaml`
  - `contracts/openapi/block-service.v1.yaml`

## 빠른 실행

```bash
# 전체 서비스 레포 동기화 + 네트워크 준비
./scripts/msa-stack.sh init

# 전체 compose up
./scripts/msa-stack.sh up

# 상태 확인
./scripts/msa-stack.sh ps
```

- 상세: [Stack Orchestration](docs/stack-orchestration.md)

## 원칙
1. Breaking change는 반드시 계약 버전 증가(`v2+`) 후 반영
2. 구현 변경보다 계약 변경 PR을 먼저 머지
3. Gateway는 외부 계약(`/v1/**`)의 유일한 노출 지점
4. 내부 서비스는 `/v1` 없는 내부 경로만 소유
