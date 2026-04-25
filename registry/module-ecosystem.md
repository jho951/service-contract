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

## 현재 서버 2계층 Platform

3계층 서비스는 1계층 OSS를 직접 조립하지 않고 2계층 platform starter/BOM과 sanctioned add-on, public SPI를 소비한다.

기준은 local `BE/platform` 구현과 각 서비스 main 브랜치 build 파일이다.
세부 사용 계약과 breaking change는 [contract-oss.md](contract-oss.md)를 source of truth로 본다.

| Platform | Current Service Baseline | Absorbs | Purpose |
| --- | --- | --- | --- |
| `platform-security` | `4.0.0` | `auth`, `ip-guard`, `rate-limiter` | 인증/인가 기본 조립, boundary, gateway header, IP guard, rate limit |
| `platform-governance` | `4.0.0` | `audit-log`, `policy-config`, plugin-policy-engine config compatibility | 감사, 운영 정책, policy config, governance decision chain |
| `platform-resource` | `4.0.0` | `file-storage`, `notification` | resource lifecycle, metadata/catalog, storage/notification orchestration |
| `platform-integrations` | `4.0.0` | platform bridge | security/resource event를 governance audit으로 연결하는 optional bridge |

### 서비스별 적용 매트릭스
| Service | Current Modules | Notes |
| --- | --- | --- |
| `gateway-service` | `platform-runtime-bom 4.0.0`, `platform-governance-starter`, `platform-security-starter`, `platform-security-hybrid-web-adapter`, `platform-security-governance-bridge` | `GatewayPlatformSecurityConfiguration`이 `GovernanceAuditSink`, additive `SecurityPolicy`, `HybridSecurityRuntime`을 등록하고, edge flow는 `GatewayPlatformSecurityWebFilter`가 소유한다. |
| `auth-service` | `platform-runtime-bom 4.0.0`, `platform-governance-starter`, `platform-security-starter`, `platform-security-governance-bridge` | `PlatformTokenIssuerPort`, `PlatformSessionIssuerPort`, `PlatformSessionSupportFactory`, `PlatformRateLimitPort`, `GovernanceAuditSink`를 서비스가 직접 제공한다. |
| `user-service` | `platform-runtime-bom 4.0.0`, `platform-governance-starter`, `platform-security-starter`, `platform-security-governance-bridge` | `UserPlatformRuntimeConfiguration`이 `GovernanceAuditSink`, JWT decoder, prod Redis 기반 `PlatformRateLimitPort`를 제공한다. |
| `authz-service` | `platform-runtime-bom 4.0.0`, `platform-governance-starter`, `platform-security-starter`, `platform-security-web-api`, `platform-security-governance-bridge` | platform-owned internal auth flow, `GovernanceAuditSink`, prod Redis 기반 `PlatformRateLimitPort`를 쓴다. 2026-04-25 CD는 stale container 제거 후 정상 배포됐다. |
| `editor-service` | `platform-runtime-bom 4.0.0`, `platform-governance/security/resource BOM 4.0.0`, `platform-governance-starter`, `platform-security-starter`, `platform-security-web-api`, `platform-resource-starter`, `platform-resource-jdbc`, `platform-security-governance-bridge 4.0.0`, `platform-resource-governance-bridge 4.0.0`, runtime `platform-resource-support-local` | `GovernanceAuditSink`, prod Redis 기반 `PlatformRateLimitPort`, prod filesystem `ResourceContentStore`까지 platform contract 기준으로 정리됐다. 다만 prod filesystem backing은 현재 service-owned port 구현이며, `editor v2`에서 platform-resource optional support module로 승격할 계획이다. |
| `monitoring-service` | only if it becomes a custom Spring Boot/admin API service | observability wrapper는 현재 2계층 platform 소비 대상이 아니다. |
| `redis-service` | not applied | real Redis infra는 현재 2계층 platform 소비 대상이 아니다. |

### 적용 기준
- 3계층 서비스는 기본적으로 `platform-*-starter`, release-train BOM, sanctioned add-on, public SPI만 안다.
- 서비스 차이는 platform 내부 모듈이 아니라 `platform.security.service-role-preset` 같은 preset과 service-owned collaborator bean으로 표현한다.
- bridge artifact는 기본 탑재가 아니라 두 platform의 event/audit 연결이 필요할 때만 추가한다.
- 서비스는 보안/감사 framework를 만들지 않고 도메인 rule과 use case만 구현한다.
- platform-governance의 공식 운영 sink SPI는 `GovernanceAuditSink`다.
- governance audit entry publish SPI는 `GovernanceAuditRecorder`다.
- `AuditLogRecorder`는 제거된 legacy seam으로 보고, mainline starter surface나 새 서비스 구현 가이드에서 설명하지 않는다.
- `platform-security-auth-bridge-starter`, `platform-security-ratelimit-bridge-starter`는 optional migration path이며, 현재 `gateway/auth/authz/user/editor` mainline baseline에는 포함하지 않는다.
- `redis-service`가 실제 Redis 인프라라면 2계층 platform 적용 대상이 아니다.
- `monitoring-service`가 Prometheus/Grafana wrapper라면 2계층 platform 적용 대상이 아니다.

### 현재 적용 예외
- `gateway-service`는 `platform-security-hybrid-web-adapter`를 sanctioned add-on으로 쓰지만, gateway 고유 `GatewayPlatformSecurityWebFilter`와 `HybridSecurityRuntime`이 edge filter chain을 계속 소유한다. `GatewayApplication`은 `PlatformSecurityHybridWebAdapterAutoConfiguration`만 exclude 한다.
- `editor-service`는 더 이상 `platform-resource-core` 구현을 직접 생성하지 않는다. local fallback은 runtime `platform-resource-support-local`이 맡고, 서비스는 `platform-security-web-api`로 custom `SecurityFailureResponseWriter`를 구현한다. prod storage backing도 `ResourceContentStore` port 기준으로 정리했다.

### 4.0.0 Rollout Status
- 2026-04-25 기준 `gateway-service`, `auth-service`, `authz-service`, `user-service`, `editor-service`는 published `platform 4.0.0`을 소비하는 main 브랜치 상태로 정리됐다.
- 서비스 CD는 5개 모두 성공했고, `authz-service`는 stale `authz-service` container를 recreate 전에 제거하는 guard를 추가해 single-EC2 배포를 안정화했다.
- 2026-04-25 기준 `gateway/auth/authz/user/editor` 5개 서비스 compile surface에는 raw 1계층 직접 의존이 남아 있지 않다.

### 감사 이벤트 대상
| Service | Representative Events |
| --- | --- |
| `auth-service` | 로그인 성공/실패, MFA, refresh, logout, session revoke |
| `authz-service` | 정책 생성/수정/삭제, role grant/revoke, delegation, authorization decision |
| `user-service` | 프로필 수정, visibility/privacy 변경, social link add/remove |
| `Gateway` | 인증 프록시 허용/거부, admin IP guard 차단, header normalization |
| `Editor` / `editor-service` | 문서/블록 수정, 공유, 삭제, 복구, 게시 |
| `redis-service` | 캐시 무효화, 운영자 수준 키 조작 |

## 추후 확장 서버 모듈
| Module | Repo | Purpose |
| --- | --- | --- |
| `ip-guard` | `https://github.com/jho951/ip-guard.git` | 관리자 접근 제한, IP allow/deny, edge 보호 정책 |
| `rate-limiter` | `https://github.com/jho951/ratelimiter.git` | 요청 제한, abuse 방지, 보호 정책 |
| `feature-flag` | `https://github.com/jho951/feature-flag.git` | 기능 노출 제어, 점진 롤아웃, 실험 플래그 |
| `policy-config` | `https://github.com/jho951/policy-config.git` | 정책 정의/배포/버전 관리 |

### 적용 방향
- `ip-guard`는 Gateway의 관리자/internal route 경계에서 접근 제한 정책으로 적용한다.
- `rate-limiter`는 Gateway 또는 Auth/Authz 경계에서 보호 정책과 함께 적용한다.
- `feature-flag`는 프론트/백엔드의 점진 배포와 실험 플로우에 사용한다.
- `policy-config`는 Authz 정책 모델, delegation, versioning과 결합해 운영한다.

## 책임 분리
| Area | Source of Truth |
| --- | --- |
| UI 컴포넌트 구현 | `Ui-components-module` 또는 각 프론트엔드 레포 |
| 인증/세션 | `auth` + `auth-service` 계약 |
| 감사 추적 | `audit-log` + 서비스 감사 계약 |
| 정책 평가 | `plugin-policy-engine` + `repositories/authz-service/*` |
| 관리자 접근 제한 | `ip-guard` + Gateway 정책 |
| 요청 제한 | `rate-limiter` + Gateway/Authz 정책 |
| 기능 노출 | `feature-flag` + 각 서비스/프론트 계약 |
| 정책 정의 | `policy-config` + `repositories/authz-service/*` |

## 계약 연결
- 프론트엔드 소비자 계약은 `contract.lock.yml`과 README contract source 섹션에서 외부 UI 모듈 사용 여부를 기록한다.
- 서버 확장 모듈은 `Authz` 정책/캐시/버전 문서와 함께 갱신한다.
- 외부 모듈이 추가되면 이 문서를 먼저 갱신하고, 그다음 서비스 레포 README와 `contract.lock.yml`을 맞춘다.
