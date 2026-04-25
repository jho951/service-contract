# Platform 4.0.0 Adoption Guide

이 문서는 서비스 레포가 `platform 4.0.0`을 적용할 때 필요한 artifact, extension point, 금지 경로, 검증 순서를 한 번에 정리한다.

기준 문서는 [contract-oss.md](contract-oss.md)이고, 이 문서는 실제 적용 절차와 서비스별 체크리스트에 집중한다.

## Quick Start

기본 repository 해석 순서:

```gradle
dependencyResolutionManagement {
    repositories {
        mavenLocal()
        mavenCentral()
        ['platform-governance', 'platform-security', 'platform-integrations', 'platform-resource'].each { repoName ->
            maven {
                url = uri("https://maven.pkg.github.com/jho951/${repoName}")
                credentials {
                    username = providers.gradleProperty('githubPackagesUsername')
                        .orElse(providers.environmentVariable('GITHUB_ACTOR'))
                        .orElse('jho951')
                        .get()
                    password = providers.gradleProperty('githubPackagesToken')
                        .orElse(providers.environmentVariable('GH_PACKAGES_TOKEN'))
                        .orElse(providers.environmentVariable('GH_TOKEN'))
                        .orElse(providers.environmentVariable('GITHUB_TOKEN'))
                        .get()
                }
            }
        }
    }
}
```

기본 의존성:

```gradle
dependencies {
    implementation platform("io.github.jho951.platform:platform-runtime-bom:4.0.0")
    implementation "io.github.jho951.platform:platform-security-starter"
    implementation "io.github.jho951.platform:platform-governance-starter"
}
```

## Rollout Status

2026-04-25 기준 현재 배포 상태:

- `platform-security`, `platform-governance`, `platform-resource`, `platform-integrations`는 GitHub Packages private `4.0.0` publish가 완료됐다.
- `gateway-service`, `auth-service`, `authz-service`, `user-service`, `editor-service`는 published `4.0.0` coordinate를 소비하는 main 브랜치 상태로 반영됐다.
- 5개 서비스 CD는 모두 성공했다. `authz-service`는 single-EC2에서 stale `authz-service` container가 남아도 재배포되도록 `docker compose ... rm -sf authz-service || true` guard를 추가했다.
- `editor-service`의 prod resource backing도 `ResourceContentStore` port 구현으로 정리돼, 5개 서비스 compile surface에서 raw 1계층 직접 의존은 남아 있지 않다.
- 다만 `editor-service`의 prod filesystem backing은 아직 service-owned `ResourceContentStore` 구현이다. `editor v2` rollout에서는 이 경계를 `platform-resource` optional support module로 같이 승격하는 것을 목표로 한다.

필요할 때만 추가하는 sanctioned add-on:

- `platform-security-governance-bridge`
- `platform-resource-governance-bridge`
- `platform-security-hybrid-web-adapter`
- `platform-security-web-api`
- `platform-resource-starter`
- `platform-resource-jdbc`
- runtime/local only `platform-security-support-local`, `platform-resource-support-local`

## Capability Map

### Governance Audit

서비스가 구현해야 하는 기본 계약:

- 운영 sink: `GovernanceAuditSink`
- entry publish helper: `GovernanceAuditRecorder`

사용 원칙:

- 서비스는 더 이상 `AuditSink`, `AuditLogger`, `AuditLogRecorder`를 governance 공식 SPI로 사용하지 않는다.
- security/resource 이벤트를 governance audit으로 연결할 때만 `platform-security-governance-bridge`, `platform-resource-governance-bridge`를 추가한다.

### Token / Session Issuance

인증 원천 서비스는 아래 port를 직접 제공한다.

- `PlatformTokenIssuerPort`
- `PlatformSessionIssuerPort`
- `PlatformSessionSupportFactory`

금지:

- `TokenService`, `SessionStore`를 서비스 mainline compile contract처럼 설명하거나 노출하는 것
- `platform-security-auth-bridge-starter`를 기본 경로처럼 채택하는 것

### Rate Limit

서비스가 제공해야 하는 contract:

- `PlatformRateLimitPort`

금지:

- `RateLimiter`, `RateLimitDecision`, `RateLimitPlan`을 서비스 기본 compile surface로 두는 것
- `rate-limiter-core`, `rate-limiter-spi`를 production dependency로 추가하는 것

예외:

- raw rate-limiter는 migration-only bridge path나 내부 테스트에서만 허용한다.

### Edge / Gateway

Gateway/edge 서비스가 주로 쓰는 surface:

- `platform-security-hybrid-web-adapter`
- `SecurityFailureResponseWriter`
- `SecurityContextResolver`
- additive `SecurityPolicy`
- `HybridSecurityRuntime`

### Resource

문서/파일 서비스가 기본으로 보는 surface:

- `ResourceContentStore`
- `ResourceLifecyclePublisher`
- `ResourceCatalog`

금지:

- `file-storage-*` raw 좌표를 서비스 public compile contract로 설명하는 것
- `platform-resource-core` 구현 타입을 직접 생성하는 것

## 서비스별 체크리스트

### gateway-service

- `platform-runtime-bom 4.0.0`
- `platform-security-starter`
- `platform-governance-starter`
- `platform-security-hybrid-web-adapter`
- `platform-security-governance-bridge`
- 서비스 구현 포인트:
  - `HybridSecurityRuntime`
  - additive `SecurityPolicy`
  - `GovernanceAuditSink`

### auth-service

- `platform-runtime-bom 4.0.0`
- `platform-security-starter`
- `platform-governance-starter`
- `platform-security-governance-bridge`
- 서비스 구현 포인트:
  - `PlatformTokenIssuerPort`
  - `PlatformSessionIssuerPort`
  - `PlatformSessionSupportFactory`
  - `PlatformRateLimitPort`
  - `GovernanceAuditSink`

### user-service

- `platform-runtime-bom 4.0.0`
- `platform-security-starter`
- `platform-governance-starter`
- `platform-security-governance-bridge`
- 서비스 구현 포인트:
  - `PlatformRateLimitPort`
  - `GovernanceAuditSink`
  - 필요 시 `GovernanceAuditRecorder` 직접 사용

### authz-service

- `platform-runtime-bom 4.0.0`
- `platform-security-starter`
- `platform-governance-starter`
- 필요 시 `platform-security-web-api`
- 필요 시 `platform-security-governance-bridge`
- 서비스 구현 포인트:
  - platform-owned internal auth flow
  - `PlatformRateLimitPort`
  - `GovernanceAuditSink`

### editor-service

- `platform-runtime-bom 4.0.0`
- `platform-security-starter`
- `platform-governance-starter`
- `platform-resource-starter`
- `platform-resource-jdbc`
- `platform-security-governance-bridge`
- `platform-resource-governance-bridge`
- 서비스 구현 포인트:
  - `SecurityFailureResponseWriter`
  - `GovernanceAuditSink`
  - `PlatformRateLimitPort`
  - `ResourceContentStore`
  - `ResourceLifecyclePublisher`
- 후속 계획:
  - 현재 prod filesystem backing은 service-owned `ResourceContentStore` 구현으로 유지한다.
  - `editor v2` rollout에서는 `platform-resource-support-filesystem` 또는 동등한 platform-owned prod backing 모듈로 승격해 서비스 bean을 제거한다.

## Legacy Replacement

| 제거된 경로 | 4.0.0 기준 대체 경로 |
| --- | --- |
| `AuditSink` | `GovernanceAuditSink` |
| `AuditLogRecorder` | `GovernanceAuditRecorder` |
| `platform-security-auth-bridge-starter` 기본 사용 | `PlatformTokenIssuerPort`, `PlatformSessionIssuerPort`, `PlatformSessionSupportFactory` 직접 제공 |
| `platform-security-ratelimit-bridge-starter` 기본 사용 | `PlatformRateLimitPort` 직접 제공 |
| `platform.governance.plugin-policy-engine.*` | `platform.governance.policy-config.*` |
| `GovernanceEngineFailurePolicy.AUDIT_AND_DENY` | `GovernanceEngineFailurePolicy.DENY` |
| `PolicyConfigSource.isOperational()` | `PolicyConfigSource.properties().containsKey(...)` 또는 호출부 정책으로 대체 |

## Dependency Placement And Verification Order

항상 아래 순서를 따른다.

1. 먼저 의존성이 필요한 위치를 고른다: `main`, `test`, `testFixtures`, `publication`.
2. security류 raw dependency는 테스트가 깨졌더라도 production scope에 넣지 않는다.
3. governance류는 publish 전 `pom`/`.module` metadata 기준으로 외부 노출 dependency만 본다.
4. 수정 후에는 `dependencies`, `outgoingVariants`, `publishToMavenLocal` 기준으로 실제 노출 경로를 검증한다.

### Security Maintainer Rule

- raw `rate-limiter-*`, raw `auth-*`는 내부 테스트나 migration bridge가 아니면 `implementation` 또는 `testImplementation`에만 둔다.
- service-facing module의 `api` 또는 published metadata에 raw 좌표가 보이면 실패로 본다.

### Governance Maintainer Rule

- `audit-log-*`, `policy-config-*`, `plugin-policy-engine-*`는 adapter 내부 구현에 남을 수 있다.
- published `pom`/`.module`에 raw 좌표가 직접 나오면 실패로 본다.

## Verification Commands

security scope 확인 예시:

```bash
./gradlew -q :platform-security-core:dependencyInsight --configuration compileClasspath --dependency rate-limiter
./gradlew -q :platform-security-core:dependencyInsight --configuration testCompileClasspath --dependency rate-limiter
./gradlew -q :platform-security-core:outgoingVariants
./gradlew :platform-security-core:publishToMavenLocal
```

governance publish surface 확인 예시:

```bash
./gradlew -q :platform-governance-core:dependencies --configuration compileClasspath
./gradlew -q :platform-governance-core:outgoingVariants
./gradlew :platform-governance-core:publishToMavenLocal
```

service 적용 후 기본 검증:

```bash
./gradlew :common:compileJava :app:compileJava
```

## Read Next

- 규칙과 금지 경로: [contract-oss.md](contract-oss.md)
- 서비스 baseline과 matrix: [module-ecosystem.md](module-ecosystem.md)
- 서비스별 계약: `repositories/*/README.md`
