# Service Contract

이 레포는 MSA 전체의 **계약 기준서**입니다.

실행 코드는 각 서비스 레포에 있고, 이 레포는 서비스들이 맞춰야 하는 API, 책임 경계, 헤더, 에러, 버전 정책을 관리합니다.

## 왜 필요한가
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
