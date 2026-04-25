# Contract OSS

이 문서는 `1계층 OSS -> 2계층 platform -> 3계층 service` 사용 계약과, 최근 2계층 변경으로 생긴 사용법 변경사항을 명세한다.

기준은 local `BE/platform/*`, `BE/services/*` 구현과 이 `contract` 레포의 registry 문서다.

## 목적

- 3계층 서비스가 어떤 artifact와 SPI를 공식 compile surface로 소비해야 하는지 고정한다.
- 2계층이 raw 1계층 library를 어디까지 내부로 숨겨야 하는지 고정한다.
- breaking change와 migration-only add-on을 구분한다.
- 서비스 마이그레이션 시 sanctioned path와 금지 path를 명확히 한다.

## 계층 규칙

- 의존 방향은 항상 `3계층 -> 2계층 -> 1계층`이다.
- 3계층은 `2계층 BOM`, `starter`, `public API/SPI`, `configuration properties`, `sanctioned add-on`만 compile surface로 소비한다.
- 3계층은 1계층 raw 좌표를 기본 진입점으로 직접 추가하지 않는다.
- 3계층은 2계층 `autoconfigure`, `core`, `internal`, `adapter` 구현 class를 직접 import하지 않는다.
- 2계층 bridge/add-on은 기본 starter에 숨겨서 자동으로 새지 말고, 필요한 경우 explicit artifact로 추가한다.
- 2계층 public BOM은 raw 1계층 external artifact를 서비스용 public dependency management surface에 직접 실지 않는다.

## Mainline Contract

### platform-security

기본 진입점:

```gradle
dependencies {
    implementation platform("io.github.jho951.platform:platform-runtime-bom:<version>")
    implementation "io.github.jho951.platform:platform-security-starter"
}
```

3계층이 공식적으로 보는 surface:

- `PlatformTokenIssuerPort`
- `PlatformSessionIssuerPort`
- `PlatformSessionSupportFactory`
- `PlatformRateLimitPort`
- `SecurityContextResolver`
- `SecurityRequestAttributeContributor`
- `SecurityFailureResponseWriter`
- `platform.security.*` properties

3계층이 explicit add-on으로만 추가할 수 있는 것:

- `platform-security-auth-bridge-starter`
- `platform-security-ratelimit-bridge-starter`
- `platform-security-hybrid-web-adapter`
- `platform-security-web-api`
- `platform-security-policyconfig-bridge`
- `platform-security-test-support`
- `platform-security-support-local`

금지:

- `auth-core`, `auth-session`, `auth-jwt`, `auth-*` raw 좌표를 기본 진입점처럼 쓰는 것
- `rate-limiter-core`, `rate-limiter-spi` raw 좌표를 기본 진입점처럼 쓰는 것
- `TokenService`, `SessionStore`, raw `RateLimiter`를 서비스의 기본 compile contract로 설명하는 것
- `platform-security-auth` / `platform-security-rate-limit` adapter class를 서비스 코드가 직접 import하는 것

temporary migration path:

- auth/rate-limit raw bean을 아직 쓰는 서비스는 `platform-security-auth-bridge-starter`, `platform-security-ratelimit-bridge-starter`를 explicit add-on으로 추가할 수 있다.
- 이 경로를 쓰면 raw 1계층 좌표도 서비스가 직접 명시적으로 추가해야 한다.
- 이 경로는 mainline contract가 아니라 migration-only compat path다.

### platform-governance

기본 진입점:

```gradle
dependencies {
    implementation platform("io.github.jho951.platform:platform-runtime-bom:<version>")
    implementation "io.github.jho951.platform:platform-governance-starter"
}
```

3계층이 공식적으로 보는 surface:

- `GovernanceAuditSink`
- `GovernanceAuditRecorder`
- `PolicyConfigSource`
- `GovernanceDecisionEngine`
- `ViolationHandler`
- `IdentityAuditRecorder`
- `platform.governance.*` properties

금지:

- `audit-log-api`, `audit-log-core`를 3계층 mainline runtime 진입점으로 직접 쓰는 것
- `policy-config-*`, `plugin-policy-engine-config`를 서비스 기본 contract처럼 직접 설명하는 것
- `AuditSink`, `AuditLogger`, `AuditEvent`를 governance 공식 서비스 SPI로 설명하는 것
- `AuditLogRecorder`를 서비스 extension point나 공식 sink SPI로 설명하는 것

breaking change:

- governance 공식 sink SPI는 `AuditSink`가 아니라 `GovernanceAuditSink`다.
- governance audit publish SPI는 `GovernanceAuditRecorder`다.
- mainline starter는 외부 `GovernanceAuditRecorder` override를 공식 extension point로 보지 않는다.
- legacy config prefix `platform.governance.plugin-policy-engine.*`, legacy enum alias `GovernanceEngineFailurePolicy.AUDIT_AND_DENY`, legacy status method `PolicyConfigSource.isOperational()`, legacy audit recorder seam `AuditLogRecorder`는 제거됐다.
- `platform-governance-bom`은 raw `audit-log`/`policy-config`/`plugin-policy-engine-config` 좌표를 public BOM surface로 직접 관리하지 않는다.

### platform-integrations

기본 원칙:

- cross-platform bridge는 기본 starter가 아니라 explicit artifact다.
- bridge 소유권은 서비스가 아니라 `platform-integrations`가 가진다.
- bridge는 각 platform의 public contract만 연결한다.

현재 sanctioned bridge:

- `platform-security-governance-bridge`
- `platform-resource-governance-bridge`

규칙:

- security/resource -> governance bridge는 public `GovernanceAuditRecorder`를 기준으로 연결한다.
- 서비스는 bridge를 추가하더라도 governance 출력용 SPI로 `GovernanceAuditSink`를 사용한다.

### platform-resource

기본 진입점:

```gradle
dependencies {
    implementation platform("io.github.jho951.platform:platform-runtime-bom:<version>")
    implementation "io.github.jho951.platform:platform-resource-starter"
}
```

3계층이 공식적으로 보는 surface:

- `ResourceContentStore`
- `ResourceLifecyclePublisher`
- `ResourceCatalog`
- `platform.resource.*` properties

원칙:

- file-storage/notification raw 좌표는 adapter 내부에 남기고, 서비스는 resource public contract만 본다.
- 운영 backing 구현이 generic filesystem/file-storage 조합이라면 장기적으로 2계층 optional support module이 소유한다.
- 현재 `editor-service`의 prod `ResourceContentStore`는 허용된 임시 service-owned composition으로 본다.
- 이 임시 경계는 `editor v2` rollout에서 `platform-resource` optional support module로 승격하는 것을 목표로 한다.

## 변경된 사용법

| 이전 설명 | 현재 계약 |
| --- | --- |
| governance 운영 sink SPI = `AuditSink` | governance 운영 sink SPI = `GovernanceAuditSink` |
| governance 도메인 audit는 `AuditLogger` 또는 `AuditSink` 우선 | governance entry publish는 `GovernanceAuditRecorder`, 운영 sink delivery는 `GovernanceAuditSink` |
| governance 내부 audit recorder seam이 bridge/test/compat 문서에 노출됨 | 제거됨. public `GovernanceAuditRecorder`만 설명 |
| raw auth/rate-limit bridge가 base security 경계에 섞여 있음 | raw auth/rate-limit bridge는 explicit `*-bridge-starter` add-on으로만 사용 |
| adapter 모듈이 raw 1계층 deps를 transitive compile export | adapter 모듈은 raw deps를 internal implementation으로만 사용 |
| public BOM이 raw external artifact를 직접 관리 | public BOM은 platform artifact만 관리 |
| security/resource governance bridge가 `AuditLogRecorder`에 붙음 | bridge는 `GovernanceAuditRecorder`에 붙음 |

## Private Release Consumption

현재 서비스 소비 기준 버전은 `4.0.0`이다.

원칙:

- 플랫폼 배포본은 GitHub Packages private package로 publish한다.
- 서비스는 기본적으로 GitHub Packages에 있는 `4.0.0` platform artifact를 소비한다.
- local 검증은 `publishToMavenLocal` 후 `mavenLocal()` 우선순위로 같은 좌표를 소비한다.
- composite build는 `-PuseLocalPlatform=true`로만 켜고, 기본 소비 경로로 쓰지 않는다.

서비스 repository 규칙:

- `settings.gradle` 또는 중앙 repository 구성은 `mavenLocal()`, `mavenCentral()`, GitHub Packages 순으로 둔다.
- GitHub Packages credential은 `githubPackagesUsername` / `githubPackagesToken` 또는 `GH_PACKAGES_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`으로 받는다.
- 서비스 build는 platform version을 직접 소스 dependency로 include 하지 않고 published coordinate로 해석한다.

## 4.0.0 Rollout Status

2026-04-25 기준 현재 상태:

| 대상 | 상태 | 메모 |
| --- | --- | --- |
| `platform-security` | private publish 완료 | GitHub Packages `4.0.0` 사용 |
| `platform-governance` | private publish 완료 | GitHub Packages `4.0.0` 사용 |
| `platform-resource` | private publish 완료 | GitHub Packages `4.0.0` 사용 |
| `platform-integrations` | private publish 완료 | runtime BOM, governance bridge 둘 다 `4.0.0` 사용 |
| `gateway-service` | `4.0.0` mainline 적용 및 CD 성공 | published coordinate 소비 |
| `auth-service` | `4.0.0` mainline 적용 및 CD 성공 | issuer/session/rate-limit mainline port 기준 |
| `authz-service` | `4.0.0` mainline 적용 및 CD 성공 | deploy 단계에서 stale container 제거 guard 추가 |
| `user-service` | `4.0.0` mainline 적용 및 CD 성공 | `GovernanceAuditSink`, `PlatformRateLimitPort` 기준 |
| `editor-service` | `4.0.0` mainline 적용 및 CD 성공 | governance/security/resource contract 기준. prod resource backing도 `ResourceContentStore` port로 정리됨 |

## 서비스별 계약 목표

| Service | 기본 artifact | sanctioned add-on | target contract |
| --- | --- | --- | --- |
| `gateway-service` | `platform-runtime-bom`, `platform-security-starter`, `platform-governance-starter` | `platform-security-hybrid-web-adapter`, `platform-security-governance-bridge` | raw 1계층 직접 의존 없이 edge flow와 governance bridge 사용 |
| `auth-service` | `platform-runtime-bom`, `platform-security-starter`, `platform-governance-starter` | `platform-security-governance-bridge` | `PlatformTokenIssuerPort`, `PlatformSessionIssuerPort`, `PlatformSessionSupportFactory`, `PlatformRateLimitPort` 기준 |
| `user-service` | `platform-runtime-bom`, `platform-security-starter`, `platform-governance-starter` | `platform-security-governance-bridge` | `GovernanceAuditSink`, `GovernanceAuditRecorder`, `PlatformRateLimitPort` 기준 |
| `authz-service` | `platform-runtime-bom`, `platform-security-starter`, `platform-governance-starter` | 필요 시 `platform-security-web-api`, `platform-security-governance-bridge` | `GovernanceAuditSink`, `PlatformRateLimitPort`, platform-owned internal auth flow 기준 |
| `editor-service` | `platform-runtime-bom`, `platform-security-starter`, `platform-governance-starter`, `platform-resource-starter` | `platform-security-web-api`, `platform-security-governance-bridge`, `platform-resource-governance-bridge`, runtime `platform-resource-support-local` | `GovernanceAuditSink`, `PlatformRateLimitPort`, resource public contract 기준 |
| `monitoring-service` | not applied by default | 없음 | 현재 2계층 platform 주 소비 대상 아님 |
| `redis-service` | not applied | 없음 | 현재 2계층 platform 주 소비 대상 아님 |

## Removed Legacy Surface

아래 항목은 2계층 mainline contract에서 제거됐다.

- `platform-security-legacy-compat`
- `platform.security.auth.legacy-secret.*`
- `platform.governance.plugin-policy-engine.*` deprecated alias
- `GovernanceEngineFailurePolicy.AUDIT_AND_DENY`
- `PolicyConfigSource.isOperational()`
- governance internal seam `AuditLogRecorder`

규칙:

- 새 서비스와 새 문서는 제거된 이름을 기본 경로처럼 설명하지 않는다.
- 기존 서비스가 이 항목을 아직 쓰고 있으면 platform 버전 업그레이드 전에 제거해야 한다.
- migration 문서에는 제거 전 이름과 대체 경로를 같이 남긴다.

## 서비스 마이그레이션 규칙

1. contract 문서를 먼저 갱신한다.
2. 서비스 direct raw dep를 없앨 수 있으면 즉시 제거한다.
3. 제거가 당장 어렵다면 bridge starter + explicit raw dep 조합을 temporary migration path로만 사용한다.
4. governance audit 구현은 `GovernanceAuditSink`, `GovernanceAuditRecorder` 기준으로 옮긴다.
5. service README, `contract.lock.yml`, adoption 문서를 함께 갱신한다.

## Source Of Truth

- 계층/소유권: [service-ownership.md](service-ownership.md)
- 플랫폼/모듈 생태계: [module-ecosystem.md](module-ecosystem.md)
- AI agent 수행 절차: [ai-agent-playbook.md](ai-agent-playbook.md)
