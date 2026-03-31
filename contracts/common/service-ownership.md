# Service Ownership

## Source of Truth
| Repo | Branch | Responsibility |
|---|---|---|
| `Api-gateway-server` | `main` | 외부 라우팅, prefix strip, trusted header 재주입, admin 경로 permission 위임 |
| `Auth-server` | `main` | 인증/인가 컨텍스트, SSO 세션/토큰, 사용자 인증 상태 판단 |
| `Authz-server` | `main` | 관리자 경로 인가, RBAC 정책, 감사 추적, health/ready, 권한 판정 API |
| `User-server` | `main` | 사용자 마스터 데이터, 소셜 링크 소유권, 프로필 가시성/개인정보 공개 범위, 내부 사용자 생성/조회 |
| `Redis-server` | `main` | 캐시/세션 저장 계층 운영 표준, gateway/permission cache prefix 소유 |
| `Block-server` | `main` | 문서/블록 도메인, editor backend 데이터 소유 |

## Contract Consumers
| Repo | Branch | Role |
|---|---|---|
| `Editor-page` | `main` | 에디터 UI 소비자 |
| `Explain-page` | `main` | 설명 UI 소비자 |

## 주의
- 코드 SoT는 각 서비스 레포
- 인터페이스 SoT는 본 `contract` 레포
- `Authz-server`와 `Redis-server`는 Gateway의 인증/인가 캐시 흐름과 직접 연결되므로, 계약 변경 시 Gateway 문서도 함께 갱신한다.
- 서비스 책임은 구현 세부가 아니라 계약 소유권을 기준으로 정의한다.
- 권한의 진실은 `Authz-server`, 공개 범위는 `User-server`, 최종 실행은 소비자 서비스가 각자 책임진다.
