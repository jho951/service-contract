# Adoption Matrix

| Service | Repo | Branch | Sync File | Status | Notes |
|---|---|---|---|---|---|
| Gateway | https://github.com/jho951/Api-gateway-server | main | `CONTRACT_SYNC.md` | adopted | 외부 `/v1/**` 경계와 permission 위임을 소유 |
| Auth | https://github.com/jho951/Auth-server | main | `CONTRACT_SYNC.md` | adopted | 로그인/세션/토큰 계약을 소유 |
| Authz | https://github.com/jho951/Authz-server | main | `CONTRACT_SYNC.md` | adopted | 관리자 RBAC와 감사 추적 계약을 소유 |
| User | https://github.com/jho951/User-server | main | `CONTRACT_SYNC.md` | adopted | 사용자/소셜 링크 및 프로필 가시성/개인정보 공개 정책을 소유 |
| Redis | https://github.com/jho951/Redis-server | main | `CONTRACT_SYNC.md` | adopted | gateway/permission 캐시 키 계약을 소유 |
| Block | https://github.com/jho951/Block-server | main | `CONTRACT_SYNC.md` | adopted | 문서/블록 API 계약을 소유 |
| Editor-page | https://github.com/jho951/Editor-page | main | `CONTRACT_SYNC.md` | adopted | editor UI 소비자 |
| Explain-page | https://github.com/jho951/Explain-page | main | `CONTRACT_SYNC.md` | adopted | 설명 UI 소비자 |

## 운영 기준
- `adopted`는 계약 허브와 서비스 레포가 `CONTRACT_SYNC.md` 기준으로 동기화되는 상태를 의미한다.
- `Authz`와 `Redis`는 Gateway 흐름에 직접 영향을 주므로, 관련 계약 변경은 우선순위가 높다.
- `User`는 profile visibility/privacy 정책도 함께 다루므로, 공개 필드 변화가 있으면 contract와 서비스 README를 같이 갱신한다.
