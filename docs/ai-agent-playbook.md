# AI Agent Playbook

AI 에이전트가 서비스 레포를 수정할 때, 계약 Source of Truth를 기준으로 일관된 변경을 만들기 위한 실행 절차입니다.

## 1) 기본 원칙
- 코드 Source of Truth: 각 서비스 레포(`gateway/auth/user/redis/block`)
- 인터페이스 Source of Truth: 이 `contract` 레포
- 순서: `contract 변경 -> 서비스 구현 변경`

## 2) 에이전트 입력값
- 대상 서비스와 브랜치
  - Gateway: `Api-gateway-server` / `main`
  - Auth: `Auth-server` / `main`
  - Authz: `Authz-server` / `main`
  - User: `User-server` / `main`
  - Redis: `Redis-server` / `main`
  - Block: `Block-server` / `dev`
  - Editor-page: `Editor-page` / `main`
  - Explain-page: `Explain-page` / `main`
- 변경 유형: non-breaking 또는 breaking
- 관련 계약 문서 경로
  - `contracts/common/routing.md`
  - `contracts/common/headers.md`
  - `contracts/common/security.md`
  - `contracts/auth/README.md`
  - `contracts/auth/api.md`
  - `contracts/auth/security.md`
  - `contracts/auth/ops.md`
  - `contracts/auth/errors.md`
  - `contracts/permission/README.md`
  - `contracts/permission/api.md`
  - `contracts/permission/rbac.md`
  - `contracts/permission/audit.md`
  - `contracts/permission/security.md`
  - `contracts/permission/ops.md`
  - `contracts/permission/errors.md`
  - `contracts/user/README.md`
  - `contracts/user/api.md`
  - `contracts/user/security.md`
  - `contracts/user/ops.md`
  - `contracts/user/errors.md`
  - `contracts/redis/README.md`
  - `contracts/redis/keys.md`
  - `contracts/redis/security.md`
  - `contracts/redis/ops.md`
  - `contracts/gateway/errors.md`
  - `contracts/common/env.md`
  - `contracts/openapi/*.yaml`

## 3) 표준 수행 절차
1. 변경 요구를 계약 항목으로 분해한다.
2. `contract` 레포를 먼저 수정한다.
3. OpenAPI를 함께 갱신한다.
4. `contracts/common/adoption-matrix.md` 상태를 업데이트한다.
5. 각 서비스 레포 구현을 계약과 동일하게 맞춘다.
6. 서비스 레포마다 `CONTRACT_SYNC.md`를 최신 계약 SHA로 갱신한다.
7. smoke test 또는 계약 테스트로 검증한다.
8. PR 본문에 계약 SHA, 변경 항목, 검증 결과를 기록한다.

## 4) 서비스별 수정 책임
- Gateway: 외부 `/v1/**` 경계, stripPrefix, trusted header 재주입, INTERNAL secret 검사
- Auth: SSO/토큰 발급, gateway 전달 헤더/토큰 계약 수용
- Authz: 권한 정책/역할 판정, 접근 제어 계약 수용
- User: 사용자/소셜 링크 소유권, `/users/**`, `/internal/users/**` 계약 수용
- Redis: 세션/캐시 저장 계층 운영 계약
- Block(dev): 문서/블록 도메인 API 계약 수용
- Editor-page: 계약 API를 소비하는 프론트엔드 UI/플로우 반영
- Explain-page: 계약 API를 소비하는 프론트엔드 UI/플로우 반영

## 5) PR 체크리스트
- [ ] 계약 문서 수정 완료
- [ ] OpenAPI 수정 완료
- [ ] 구현 레포 반영 완료
- [ ] `CONTRACT_SYNC.md`에 contract SHA 반영
- [ ] 테스트/스모크 검증 완료
- [ ] breaking change면 migration 절차 포함

## 6) 출력 템플릿
- 에이전트는 [Agent Task Template](examples/agent-task-template.md) 형식을 사용한다.

## 7) 자동화 게이트(권장)
- 서비스 PR CI에서 `contract-impact-check.sh`를 실행한다.
- 참조: [Contract Automation](contract-automation.md)
- 계약 영향 변경이 감지되면 `CONTRACT_SYNC.md` 갱신 없이는 머지되지 않도록 설정한다.
