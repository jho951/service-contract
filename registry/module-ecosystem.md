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

3계층 서비스는 1계층 OSS를 직접 조립하지 않고 2계층 platform starter/BOM을 소비한다.

기준은 `https://github.com/jho951/oss-contract.git`의 `registry/layer2`와 `repositories/layer2`다.

| Platform | Current Version | Absorbs | Purpose |
| --- | --- | --- | --- |
| `platform-security` | `2.0.3` | `auth`, `ip-guard`, `rate-limiter` | 인증/인가 기본 조립, boundary, gateway header, IP guard, rate limit |
| `platform-governance` | `2.0.1` | `audit-log`, `policy-config`, plugin-policy-engine config compatibility | 감사, 운영 정책, policy config, governance decision chain |
| `platform-resource` | `2.0.0` | `file-storage`, `notification` | resource lifecycle, metadata/catalog, storage/notification orchestration |
| `platform-integrations` | `1.0.1` 기준 | platform bridge | security/resource event를 governance audit으로 연결하는 optional bridge |

### 서비스별 적용 매트릭스
| Service | Security | Governance | Resource | Bridge |
| --- | --- | --- | --- | --- |
| `gateway-service` | required, `EDGE` preset | required | not used | `platform-security-governance-bridge` |
| `auth-service` | required, `ISSUER` preset | required | usually not used | `platform-security-governance-bridge` |
| `user-service` | required, `API_SERVER` preset | required | optional | `platform-security-governance-bridge` |
| `authz-service` | required, `INTERNAL_SERVICE` or `API_SERVER` preset | required | not used | `platform-security-governance-bridge` |
| `editor-service` | required, `API_SERVER` preset | required | required | `platform-security-governance-bridge`, `platform-resource-governance-bridge` |
| `monitoring-service` | only if it becomes a custom Spring Boot/admin API service | only if it owns operational policy | usually not used | case-by-case |
| `redis-service` | not applied for real Redis infra | not applied | not applied | not applied |

### 적용 기준
- 3계층 서비스는 `platform-*-starter`와 BOM만 안다.
- 서비스 차이는 platform 내부 모듈이 아니라 `platform.security.service-role-preset` 같은 preset으로 표현한다.
- bridge artifact는 기본 탑재가 아니라 두 platform의 event/audit 연결이 필요할 때만 추가한다.
- 서비스는 보안/감사 framework를 만들지 않고 도메인 rule과 use case만 구현한다.
- `redis-service`가 실제 Redis 인프라라면 2계층 platform 적용 대상이 아니다.
- `monitoring-service`가 Prometheus/Grafana wrapper라면 2계층 platform 적용 대상이 아니다.

### 현재 적용 예외
- `platform-resource-governance-bridge:1.0.1`은 현재 서비스 compile에서 resolve되지 않아 `editor-service`는 검증 가능한 `1.0.0`을 사용한다. 1.0.1 artifact가 publish되면 `platformIntegrationsVersion`을 `1.0.1`로 올린다.
- `editor-service`는 `platform-resource-starter`와 `platform-resource-jdbc`를 함께 사용한다. Content store는 서비스의 저장 위치만 정하는 `ResourceContentStore` SPI bean으로 제공하고, catalog/outbox는 local profile에서는 in-memory fallback, production profile에서는 JDBC adapter를 사용한다.

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
