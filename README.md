# Service Contract

## 레포 필요성

서비스가 여러 레포로 나뉘면 각 팀/서비스가 서로 다른 API 모양을 가정하기 쉽다.

```txt
Frontend -> Gateway -> Auth / Authz / User / Editor / Redis / Monitoring
```

이 레포는 위 서비스들이 같은 기준을 보도록 만드는 단일 기준점이다.

## 핵심 원칙
- Public API versioning은 Gateway가 소유한다.
- Backend service는 자기 upstream/internal API만 소유한다.
- 공통 규칙은 `shared`에 둔다.
- 기계가 검증할 schema는 `artifacts/schemas`에 둔다.
- 서비스별 계약은 `repositories/<repo>`에 둔다.
- OpenAPI 파일은 `artifacts/openapi`에 둔다.
- Terraform 공통 구조는 `shared/terraform.md`에 둔다.
- 미래 기능은 현재 계약처럼 쓰지 않고 draft/planned로 표시한다.

## 디렉토리 지도
| 위치 | 역할 |
| --- | --- |
| [registry](registry/README.md) | repository 목록, adoption 상태, 운영 절차 |
| [repositories](repositories/README.md) | 실제 GitHub repo별 계약 |
| [shared](shared/README.md) | 모든 서비스가 따르는 공통 규칙 |
| [repositories/gateway-service](repositories/gateway-service/README.md) | public route, 인증 프록시, header 재주입 |
| [repositories/auth-service](repositories/auth-service/README.md) | 로그인, refresh, SSO, session, JWT/JWKS |
| [repositories/authz-service](repositories/authz-service/README.md) | 권한 판단, RBAC, policy, introspection |
| [repositories/user-service](repositories/user-service/README.md) | 사용자 프로필, 상태, visibility |
| [repositories/editor-service](repositories/editor-service/README.md) | 문서/블록 편집 도메인 계약 |
| [repositories/editor-page](repositories/editor-page/README.md) | editor UI의 Gateway 소비 계약 |
| [repositories/explain-page](repositories/explain-page/README.md) | explain UI의 Gateway/SSO 소비 계약 |
| [repositories/redis-service](repositories/redis-service/README.md) | Redis key, cache, ops 계약 |
| [repositories/monitoring-service](repositories/monitoring-service/README.md) | metrics, logs, dashboard, alert 운영 계약 |
| [artifacts/schemas](artifacts/schemas) | 공통 JSON Schema |
| [artifacts/openapi](artifacts/openapi) | OpenAPI 계약 |
| [templates](templates) | 서비스별 `contract.lock.yml`, README, PR 템플릿 예시 |

## 읽는 순서
1. [registry/adoption-matrix.md](registry/adoption-matrix.md)에서 대상 repo와 branch를 확인한다.
2. [shared/README.md](shared/README.md)에서 공통 원칙을 확인한다.
3. Gateway가 관련되면 [repositories/gateway-service/auth-proxy.md](repositories/gateway-service/auth-proxy.md)를 먼저 본다.
4. 변경하려는 서비스의 `repositories/<repo>/README.md`를 본다.
5. API shape은 [artifacts/openapi](artifacts/openapi)의 해당 YAML로 확인한다.
6. 실제 서비스 레포 작업 후 해당 레포의 `contract.lock.yml`을 contract tag/commit에 맞추고 CI 계약 검증 결과를 확인한다.

## 변경 흐름
### 기존 구현을 문서화할 때
```txt
서비스 구현 확인
-> service-contract 문서 정렬
-> OpenAPI/schema 정렬
-> contract.lock.yml 기준 검증
```

### 새 기능을 만들 때
```txt
service-contract 계약 변경
-> 영향 서비스 확인
-> 각 서비스 구현
-> 서비스별 contract.lock.yml 갱신
-> CI 계약 검증과 smoke/test 결과 확인
```

## 적용 대상
| 영역 | 레포 |
| --- | --- |
| Gateway | https://github.com/jho951/gateway-service |
| Auth | https://github.com/jho951/auth-service |
| Authz | https://github.com/jho951/authz-service |
| User | https://github.com/jho951/user-service |
| Redis | https://github.com/jho951/redis-service |
| Editor/Document | https://github.com/jho951/editor-service |
| Monitoring | https://github.com/jho951/monitoring-service |
| Frontend | https://github.com/jho951/Editor-page, https://github.com/jho951/Explain-page |

## Frontend Baseline
| Frontend | Current API Base Pattern | Auth Transport | Notes |
| --- | --- | --- | --- |
| `Editor-page` | base URL는 `http://localhost:8080`, endpoint 상수에 `/v1/**` 포함 | cookie, `withCredentials=true` | `/v1/auth/**`, `/v1/documents/**`, `/v1/editor-operations/**`를 Gateway로 호출한다. |
| `Explain-page` | base URL를 `http://localhost:8080/v1`로 정규화하고 path는 `/auth/**` 사용 | cookie, `credentials: "include"` | `/v1` 중복 없이 Gateway auth/session API를 조립한다. |

- 두 프론트 모두 현재 구현에는 `contract.lock.yml`이 없다.
- 두 프론트 모두 backend 개별 서비스가 아니라 Gateway를 단일 브라우저 진입점으로 사용한다.

## Current Implementation Baseline
| Service | Current compose/project shape | Port | Exposure | Notes |
| --- | --- | --- | --- | --- |
| Gateway | project `gateway-service`, service `gateway-service`, alias `gateway` | `8080` | public entry | 외부 ingress와 public `/v1/**` 소유. runtime status endpoint는 `/health`, `/ready`도 함께 노출한다. editor upstream은 current runtime에서 `EDITOR_SERVICE_URL`을 canonical로 읽고, Authz 위임은 `AUTHZ_ADMIN_VERIFY_URL`을 직접 사용한다. |
| Auth | project/service `auth-service` | `8081` container, local JVM `8081` | private | 인증 원천, JWT/JWKS, session |
| Authz | base/prod compose service `authz-service` | `8084` | private | 관리자 인가, RBAC/policy. dev compose는 `authz-mysql`을 함께 띄우고 Redis는 외부 `redis`를 사용한다. env/terraform에는 `PERMISSION_*` 계열 legacy 이름이 남아 있을 수 있다. |
| User | service `user-service` | `8082` | private | 사용자 마스터/소셜/visibility |
| Editor | service `editor-service`, DB host `editor-mysql` | `8083` | private | repo 이름과 app identity를 모두 `editor-service`로 맞춘다. editor 전용 DB host와 runtime 이름도 같은 축으로 정렬한다. |
| Redis | project `redis-server-*`, service `redis-server`, shared alias `redis` | `6379` | private | 캐시/세션 저장 계층. exporter container 기본 이름은 `redis-exporter`다. |
| Monitoring | project `monitoring-server` | Prometheus `9090`, Grafana host default `3005`, Loki `3100` | operator/private | Grafana container는 `3000`을 쓰지만 compose host 기본값은 `3005`다. dev Grafana는 각 서비스 private network에 붙고 Auth/User/Editor/Authz MySQL datasource를 기본 provisioning한다. |

- contract의 서비스 디렉토리 이름은 repository 이름을 유지한다.
- canonical 내부 이름은 `auth-mysql`, `user-mysql`, `editor-mysql`, `editor-service`, `redis`, `redis-server`를 기준으로 맞춘다.
