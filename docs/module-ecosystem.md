# Module Ecosystem

이 문서는 현재 프론트엔드/서버에서 사용 중인 외부 모듈과, 추후 계약/구현 확장 시 붙을 모듈들을 정리한다.

## 현재 프론트엔드 모듈
| Module | Repo | Purpose |
| --- | --- | --- |
| `Ui-components-module` | `https://github.com/jho951/Ui-components-module` | 프론트엔드 공통 UI 컴포넌트 npm 모듈 |

### 적용 의도
- 프론트엔드 명세가 완전히 고정되기 전에도 UI 토큰과 컴포넌트 일관성을 유지한다.
- Editor-page, Explain-page 같은 소비자 레포는 이 모듈을 통해 공통 UI를 재사용할 수 있다.
- UI 구현의 세부 사항은 프론트엔드 레포가 소유하고, contract 레포는 “어떤 화면 흐름이 어떤 계약을 소비하는지”만 관리한다.

## 현재 서버 모듈
| Module | Repo | Purpose |
| --- | --- | --- |
| `auth` | `https://github.com/jho951/auth` | 인증/세션/JWT 발급 관련 핵심 모듈 |
| `audit-log` | `https://github.com/jho951/audit-log` | 감사 추적과 운영 이벤트 기록 모듈 |

### 현재 상태
- `auth`는 인증 원천과 세션 발급 흐름에 사용한다.
- `audit-log`는 권한/인증/운영 이벤트의 추적과 증적에 사용한다.
- 두 모듈은 현재 아키텍처의 필수 기반이며, contract 문서는 이들의 책임 경계를 서비스 계약과 함께 고정한다.

## 추후 확장 서버 모듈
| Module | Repo | Purpose |
| --- | --- | --- |
| `ip-guard` | `https://github.com/jho951/ip-guard` | 관리자 접근 제한, IP allow/deny, edge 보호 정책 |
| `rate-limiter` | `https://github.com/jho951/rate-limiter` | 요청 제한, abuse 방지, 보호 정책 |
| `feature-flag` | `https://github.com/jho951/feature-flag` | 기능 노출 제어, 점진 롤아웃, 실험 플래그 |
| `policy-config` | `https://github.com/jho951/policy-config` | 정책 정의/배포/버전 관리 |

### 적용 방향
- `ip-guard`는 Gateway와 Authz 경계에서 관리자 접근 제한 정책으로 적용한다.
- `rate-limiter`는 Gateway 또는 Auth/Authz 경계에서 보호 정책과 함께 적용한다.
- `feature-flag`는 프론트/백엔드의 점진 배포와 실험 플로우에 사용한다.
- `policy-config`는 Authz 정책 모델, delegation, versioning과 결합해 운영한다.

## 책임 분리
| Area | Source of Truth |
| --- | --- |
| UI 컴포넌트 구현 | `Ui-components-module` 또는 각 프론트엔드 레포 |
| 인증/세션 | `auth` + `Auth-server` 계약 |
| 감사 추적 | `audit-log` + 서비스 감사 계약 |
| 관리자 접근 제한 | `ip-guard` + Gateway/Authz 정책 |
| 요청 제한 | `rate-limiter` + Gateway/Authz 정책 |
| 기능 노출 | `feature-flag` + 각 서비스/프론트 계약 |
| 정책 정의 | `policy-config` + `contracts/authz/*` |

## 계약 연결
- 프론트엔드 소비자 계약은 `CONTRACT_SYNC.md`와 README contract source 섹션에서 외부 UI 모듈 사용 여부를 기록한다.
- 서버 확장 모듈은 `Authz` 정책/캐시/버전 문서와 함께 갱신한다.
- 외부 모듈이 추가되면 이 문서를 먼저 갱신하고, 그다음 서비스 레포 README/동기화 문서를 맞춘다.
