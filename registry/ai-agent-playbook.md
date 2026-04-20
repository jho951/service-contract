# AI Agent Playbook

AI 에이전트가 서비스 레포를 수정할 때, `service-contract`를 기준으로 일관된 변경을 만들기 위한 실행 절차입니다.

## 1) 기본 원칙
- 코드 Source of Truth: 각 서비스 레포(`gateway/auth/authz/user/redis/block/monitoring`)
- 인터페이스 Source of Truth: 이 `contract` 레포
- 순서: `contract 변경 -> 서비스 구현 변경`

## 2) 에이전트 입력값
- 대상 서비스와 브랜치
  - Gateway: `gateway-service` / `main`
  - Auth: `auth-service` / `main`
  - Authz: `authz-service` / `main`
  - User: `user-service` / `main`
  - Redis: `redis-service` / `main`
  - Editor: `editor-service` / `dev`
  - Monitoring: `monitoring-service` / `main`
  - Editor-page: `Editor-page` / `master`
  - Explain-page: `Explain-page` / `main`
- 변경 유형: non-breaking 또는 breaking
- 관련 계약 문서 경로
  - `registry/module-ecosystem.md`
  - `shared/decision-criteria.md`
  - `shared/routing.md`
  - `shared/headers.md`
  - `shared/security.md`
  - `repositories/auth-service/README.md`
  - `repositories/auth-service/api.md`
  - `repositories/auth-service/security.md`
  - `repositories/auth-service/ops.md`
  - `repositories/auth-service/errors.md`
  - `repositories/authz-service/README.md`
  - `repositories/authz-service/api.md`
  - `repositories/authz-service/rbac.md`
  - `repositories/authz-service/audit.md`
  - `repositories/authz-service/security.md`
  - `repositories/authz-service/ops.md`
  - `repositories/authz-service/errors.md`
  - `repositories/user-service/README.md`
  - `repositories/user-service/api.md`
  - `repositories/user-service/security.md`
  - `repositories/user-service/ops.md`
  - `repositories/user-service/errors.md`
  - `repositories/redis-service/README.md`
  - `repositories/redis-service/keys.md`
  - `repositories/redis-service/security.md`
  - `repositories/redis-service/ops.md`
  - `repositories/monitoring-service/README.md`
  - `repositories/monitoring-service/targets.md`
  - `repositories/monitoring-service/security.md`
  - `repositories/monitoring-service/ops.md`
  - `shared/audit.md`
  - `repositories/gateway-service/errors.md`
  - `shared/env.md`
  - `artifacts/openapi/*.yaml`

## 3) 표준 수행 절차
1. 변경 요구를 계약 항목으로 분해한다.
2. `contract` 레포를 먼저 수정한다.
3. OpenAPI를 함께 갱신한다.
4. `registry/adoption-matrix.md` 상태를 업데이트한다.
5. 각 서비스 레포 구현을 계약과 동일하게 맞춘다.
6. 서비스 레포마다 `contract.lock.yml`을 최신 계약 ref/SHA로 갱신한다.
7. smoke test 또는 계약 테스트로 검증한다.
8. PR 본문에 계약 SHA, 변경 항목, 검증 결과를 기록한다.

## 4) 서비스별 수정 책임
- Gateway: 외부 `/v1/**` 경계, stripPrefix, trusted header 재주입, INTERNAL secret 검사
- Auth: SSO/토큰 발급, gateway 전달 헤더/토큰 계약 수용
- Authz: 권한 정책/역할 판정, 정책 엔진, 접근 제어 계약 수용
- User: 사용자/소셜 링크 소유권, `/users/**`, `/internal/users/**` 계약 수용
- Redis: 세션/캐시 저장 계층 운영 계약
- Editor(dev): 문서/블록 도메인 API 계약 수용
- Monitoring: metrics/logs/dashboard/alert 운영 계약과 scrape target 수용
- Editor-page: 계약 API를 소비하는 프론트엔드 UI/플로우 반영
- Explain-page: 계약 API를 소비하는 프론트엔드 UI/플로우 반영
- Shared modules: `Ui-components-module`, `auth`, `audit-log`, `plugin-policy-engine`, `ip-guard`, `rate-limiter`, `feature-flag`, `policy-config`는 [Module Ecosystem](module-ecosystem.md)를 기준으로 기록한다.
- All services: 신규 권한/기능/정책 판단은 [Decision Criteria](../shared/decision-criteria.md)를 먼저 따른다.
- All services: 감사 이벤트는 [Common Audit Contract](../shared/audit.md)를 먼저 따른다.

## 5) PR 체크리스트
- [ ] 계약 문서 수정 완료
- [ ] OpenAPI 수정 완료
- [ ] 구현 레포 반영 완료
- [ ] `contract.lock.yml`에 contract ref/SHA 반영
- [ ] 테스트/스모크 검증 완료
- [ ] breaking change면 migration 절차 포함

## 6) 출력 템플릿
- 에이전트는 [Agent Task Template](../templates/agent-task-template.md) 형식을 사용한다.

## 7) 자동화 게이트(권장)
- 서비스 PR CI에서 `contract.lock.yml` 검증과 서비스별 계약 테스트를 실행한다.
- 참조: [Contract Automation](automation.md)
- 계약 영향 변경이 감지되면 `contract.lock.yml` 갱신과 계약 검증 없이는 머지되지 않도록 설정한다.
