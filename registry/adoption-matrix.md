# Adoption Matrix

| Service | Repo | Branch | Contract Lock | Status | Notes |
|---|---|---|---|---|---|
| Gateway | https://github.com/jho951/gateway-service | main | `contract.lock.yml` | adopted | 외부 `/v1/**` 경계와 permission 위임을 소유 |
| Auth | https://github.com/jho951/auth-service | main | `contract.lock.yml` | adopted | 로그인/세션/토큰 계약을 소유 |
| Authz | https://github.com/jho951/authz-service | main | `contract.lock.yml` | adopted | 관리자 RBAC와 감사 추적 계약을 소유 |
| User | https://github.com/jho951/user-service | main | `contract.lock.yml` | adopted | 사용자/소셜 링크 및 프로필 가시성/개인정보 공개 정책을 소유 |
| Redis | https://github.com/jho951/redis-service | main | `contract.lock.yml` | adopted | gateway/permission 캐시 키 계약을 소유 |
| Monitoring | https://github.com/jho951/monitoring-service | main | `contract.lock.yml` | adopted | metrics/logs/dashboard/alert 운영 계약을 소유 |
| audit-log | https://github.com/jho951/audit-log | main | `contract.lock.yml` | adopted | 전 서비스 공통 감사 이벤트 수집과 증적 보존을 소유 |
| Editor | https://github.com/jho951/editor-service | dev | `contract.lock.yml` | adopted | 문서/블록 API 계약을 소유 |
| Editor-page | https://github.com/jho951/Editor-page | master | `contract.lock.yml` | adopted | editor UI 소비자 |
| Explain-page | https://github.com/jho951/Explain-page | main | `contract.lock.yml` | adopted | 설명 UI 소비자 |

## 운영 기준
- `adopted`는 서비스 레포가 `contract.lock.yml`을 통해 contract ref/SHA를 고정하고 CI 계약 검증을 수행하는 상태를 의미한다.
- `Authz`와 `Redis`는 Gateway 흐름에 직접 영향을 주므로, 관련 계약 변경은 우선순위가 높다.
- `Monitoring`은 서비스 runtime 진실을 소유하지 않고, scrape target, dashboard, alert, log collection 운영 기준을 소유한다.
- `audit-log`는 모든 서비스가 공통으로 사용하는 감사 모듈이므로, 새 이벤트 타입이 생기면 서비스 레포와 contract 레포를 함께 갱신한다.
- `User`는 profile visibility/privacy 정책도 함께 다루므로, 공개 필드 변화가 있으면 contract와 서비스 README를 같이 갱신한다.
