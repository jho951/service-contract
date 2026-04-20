# Service Ownership

## 계층 분류 기준

이 문서의 계층은 전통적인 controller/service/repository n-tier가 아니라 `primitive / platform runtime / deployable service` 분류다.

| 계층 | 정의 | 상태 소유권 |
|---|---|---|
| 1계층 | 서비스명을 몰라도 성립하는 재사용 primitive library | 엔진, adapter, primitive 내부 상태만 가진다. 업무 데이터는 소유하지 않는다. |
| 2계층 | 여러 서비스를 위한 opinionated platform runtime / contract / starter | API/SPI, starter, autoconfigure, bridge, 운영 guard를 제공한다. 운영 workflow의 최종 owner가 되지 않는다. |
| 3계층 | 실제 deploy되는 service | 업무 데이터, 운영 상태, endpoint, controller, publish/revoke/history 같은 workflow의 최종 owner다. |

`platform-owned`와 `2계층`은 같은 말이 아니다. 미래에 `Governance-server`나 `Resource-metadata-server`가 생기면 플랫폼 성격을 갖더라도 deploy되고 상태/workflow를 소유하므로 3계층으로 분류한다.

의존 방향은 항상 `3계층 -> 2계층 -> 1계층`이다. 3계층은 2계층의 BOM, starter, api/spi, configuration properties만 compile surface로 소비하고, 2계층의 autoconfigure/core/internal 구현 class를 직접 import하지 않는다.

## Repo Classification

| Repo | 위치 | 계층 | 판정 |
|---|---|---|---|
| `auth` | `/module/auth` | 1계층 | 인증/JWT/session primitive |
| `audit-log` | `/module/audit-log` | 1계층 | 감사 기록 primitive |
| `file-storage` | `/module/file-storage` | 1계층 | 파일 저장 primitive |
| `ip-guard` | `/module/ip-guard` | 1계층 | IP/CIDR 평가 primitive |
| `notification` | `/module/notification` | 1계층 | 알림 발송 primitive |
| `plugin-policy-engine` | `/module/plugin-policy-engine` | 1계층 | 정책 평가 engine primitive |
| `policy-config` | `/module/policy-config` | 1계층 | 정책 설정 primitive |
| `rate-limiter` | `/module/rate-limiter` | 1계층 | 요청 제한 primitive |
| `platform-security` | `/platform/platform-security` | 2계층 | security runtime, starter, guard |
| `platform-governance` | `/platform/platform-governance` | 2계층 | governance runtime, starter, bridge |
| `platform-resource` | `/platform/platform-resource` | 2계층 | resource runtime, starter |
| `gateway-service` | `/services/gateway-service` | 3계층 | gateway deployable service |
| `auth-service` | `/services/auth-service` | 3계층 | identity issuer deployable service |
| `authz-service` | `/services/authz-service` | 3계층 | authorization decision deployable service |
| `user-service` | `/services/user-service` | 3계층 | user profile deployable service |
| `editor-service` | `/services/editor-service` | 3계층 | editor/document deployable service |
| `monitoring-service` | `/services/monitoring-service` | infra repo | observability runtime repo |
| `redis-service` | `/services/redis-service` | infra repo | Redis runtime repo |

장기적으로 infra repo는 `/infra` 같은 별도 축으로 분리해 `/services`를 deployable application service 중심으로 좁힌다.

## Source of Truth
| Repo | Branch | Responsibility |
|---|---|---|
| `gateway-service` | `main` | 외부 라우팅, prefix strip, trusted header 재주입, admin 경로 permission 위임 |
| `auth-service` | `main` | 로그인, SSO 세션/토큰 발급과 검증, 사용자 인증 상태 판단 |
| `authz-service` | `main` | 관리자 경로 인가, RBAC 정책, 감사 추적, health/ready, 권한 판정 API |
| `user-service` | `main` | 사용자 마스터 데이터, 소셜 링크 소유권, 프로필 가시성/개인정보 공개 범위, 내부 사용자 생성/조회 |
| `redis-service` | `main` | 캐시/세션 저장 계층 운영 표준, gateway/permission cache prefix 소유 |
| `monitoring-service` | `main` | Prometheus/Grafana/Loki 등 관측 스택과 공통 metric/log 수집 기준 |
| `audit-log` | `main` | 모든 서비스 감사 이벤트 수집, 정규화, 보존 정책 |
| `editor-service` | `dev` | 문서/블록 도메인, editor backend 데이터 소유 |

## Contract Consumers
| Repo | Branch | Role |
|---|---|---|
| `Editor-page` | `master` | 에디터 UI 소비자 |
| `Explain-page` | `main` | 설명 UI 소비자 |

## 주의
- 코드 SoT는 각 서비스 레포
- 인터페이스 SoT는 본 `contract` 레포
- `authz-service`와 `redis-service`는 Gateway의 인증/인가 캐시 흐름과 직접 연결되므로, 계약 변경 시 Gateway 문서도 함께 갱신한다.
- `plugin-policy-engine`은 authz-service의 정책 평가 런타임이며, 정책 모델 변경 시 Authz 문서와 함께 갱신한다.
- `audit-log`는 인증/인가/프로필/편집/운영 이벤트의 공통 감사 허브이므로, 새 이벤트가 추가되면 각 서비스 문서와 함께 갱신한다.
- 서비스 책임은 구현 세부가 아니라 계약 소유권을 기준으로 정의한다.
- 권한의 진실은 `authz-service`, 공개 범위는 `user-service`, 최종 실행은 소비자 서비스가 각자 책임진다.
- `editor-service`의 Gradle rootProject.name이 `Editor-server`인 것처럼 repo 이름과 artifact 이름이 다르면 이름 드리프트로 보고 빠르게 정리한다.
- `policy-config`, `platform-policy-api`처럼 같은 책임을 다른 이름 축으로 부르는 표현은 표준 이름을 먼저 정하고 계약 문서를 맞춘다.
