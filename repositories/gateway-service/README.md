# Gateway Contract

Gateway는 외부 public API의 진입점이다. Public route versioning, 인증 채널 판정, trusted header 재주입, upstream routing을 소유한다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/gateway-service |
| Branch | `main` |
| Contract Lock | `contract.lock.yml` |

## 책임 경계
| 영역 | Gateway 책임 |
| --- | --- |
| Public route | `/v1/**`, `/v2/**` 같은 외부 경로 소유 |
| Auth proxy | Cookie/Bearer 인증 채널 판정과 Auth-service 검증 연동 |
| Header normalization | 외부 trusted header 제거 후 내부 header 재주입 |
| Admin guard | 관리자 경로에서 Authz 검증 호출 |
| Upstream routing | public route를 service upstream route로 변환 |
| Edge response | CORS, preflight, timeout, upstream error normalization |

## Current Platform Runtime
- `gateway-service` 현재 구현은 `platform-runtime-bom 3.0.1`, `platform-governance-bom 3.0.1`, `platform-security-bom 3.0.1`을 함께 사용한다.
- 런타임 모듈은 `platform-governance-starter`, `platform-security-starter`, `platform-security-hybrid-web-adapter`, `platform-security-governance-bridge`다.
- `GatewayApplication`은 `PlatformSecurityHybridWebAdapterAutoConfiguration`만 exclude 한다. platform starter 전체를 끄지 않는다.
- `GatewayPlatformSecurityConfiguration`은 `PlatformSecurityHybridWebAdapterMarker`, additive `SecurityPolicy`, `HybridSecurityRuntime`, `AuditSink`를 등록한다.
- 실제 edge 판정 흐름은 `GatewayPlatformSecurityWebFilter`가 auth-service 검증, platform policy 평가, deny 응답, downstream identity projection을 수행하는 현재 구조다.

## 읽는 순서
1. [responsibility.md](responsibility.md): Gateway 책임과 경계
2. [auth-proxy.md](auth-proxy.md): public auth route와 Auth-service upstream mapping
3. [auth.md](auth.md): 인증 채널과 token/session 처리
4. [../../shared/headers.md](../../shared/headers.md): 공통 trusted/trace header
5. [security.md](security.md): Gateway 보안 경계
6. [cache.md](cache.md): session/admin decision cache
7. [response.md](response.md): edge response policy
8. [env.md](env.md): 환경변수
9. [errors.md](errors.md): Gateway error
10. [execution.md](execution.md): 실행/운영

## 핵심 계약
| Public route | Upstream owner |
| --- | --- |
| `/v1/auth/**` | Auth-service |
| `/v1/users/**` | User-service |
| `/v1/documents/**` | Editor/Block domain |
| `/v1/admin/**` | Gateway + Editor upstream + Authz internal verify |

- Gateway는 현재 public `/v1/permissions/**`를 직접 proxy하지 않는다.
- 관리자 경로 판정은 내부 `POST /permissions/internal/admin/verify` 호출로 수행한다.

## 라우트 등록 메모
- 계약 경계는 `/v1/users/**`, `/v1/auth/**`처럼 서비스 단위 prefix를 기준으로 본다.
- 현재 구현은 일부 public route를 exact path 단위로 등록할 수 있다.
- Gateway route 매칭은 path 기준이며 method 기준으로 route를 분리하지 않는다.
  - 예: 이미 `/v1/users/me`가 등록돼 있으면 `GET` 외에 `PATCH /v1/users/me`를 추가해도 같은 route entry를 재사용할 수 있다.
- 반대로 `/v1/users/me/preferences` 같은 새 하위 경로는 exact path 등록 구조에서는 별도 route 추가가 필요하다.
- 개별 path 등록을 줄이려면 v2에서 서비스 경계 wildcard route를 채택할 수 있다.
  - 예: `/v1/users/**`, `/v1/auth/**`
- wildcard route로 전환할 때는 route 우선순위, `PUBLIC/PROTECTED/INTERNAL/ADMIN` 경계, 미래 하위 경로의 과노출 여부를 함께 검증한다.

## 관련 문서
- [Common Routing](../../shared/routing.md)
- [Common Headers](../../shared/headers.md)
- [Common Security](../../shared/security.md)
- [Common Audit](../../shared/audit.md)
- [Gateway Public OpenAPI](../../artifacts/openapi/gateway-service.public.v1.yaml)

## 운영 배포 자산

- EC2 image-only 배포 기준 산출물은 구현 repo의 `deploy/ec2/` 아래에 둔다.
- 기본 파일은 `docker-compose.yml`, `.env.production.example`, `README.md`이고, host Nginx reverse proxy example을 함께 둔다.
