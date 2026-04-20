# Shared Contract

`shared`는 모든 서비스가 공유하는 규칙을 담는다. 특정 서비스의 세부 API가 아니라, 서비스 간 계약을 해석하는 기준이다.

## 무엇을 여기에 두나
| 문서                                               | 역할                                            |
|--------------------------------------------------|-----------------------------------------------|
| [routing.md](routing.md)                         | public route와 upstream route의 책임 분리           |
| [headers.md](headers.md)                         | trace header, trusted header, internal secret |
| [security.md](security.md)                       | 공통 보안 원칙과 trust boundary                      |
| [auth-channel-policy.md](auth-channel-policy.md) | web/native/cli/api 인증 채널 판정                   |
| [versioning.md](versioning.md)                   | 계약 버전과 public route versioning 정책             |
| [errors.md](errors.md)                           | 공통 에러 envelope와 code 관리 원칙                    |
| [audit.md](audit.md)                             | 공통 감사 이벤트 원칙                                  |
| [env.md](env.md)                                 | 공통 환경변수 작성 원칙                                 |
| [ci-cd.md](ci-cd.md)                             | 공통 CI/CD stage와 profile 기준                         |
| [terraform.md](terraform.md)                     | MSA 공통 Terraform 구조와 모듈 분리 기준                  |
| [decision-criteria.md](decision-criteria.md)     | 설계 판단 기준                                      |

## 공통 원칙
- Gateway는 public route versioning을 소유한다.
- Backend service는 자기 upstream/internal route를 소유한다.
- Downstream 서비스는 Gateway가 재주입한 trusted header만 신뢰한다.
- 공통 에러 응답은 [errors.md](errors.md)와 [error-envelope.schema.json](../artifacts/schemas/error-envelope.schema.json)을 따른다.
- 공통 감사 이벤트 원칙은 [audit.md](audit.md)를 따른다.
- OpenAPI 파일은 `artifacts/openapi`에 둔다.
- 공통 Terraform 구조는 [terraform.md](terraform.md)를 따른다.

## 서비스별 계약
| 서비스 | 문서 |
| --- | --- |
| Gateway | [../repositories/gateway-service/README.md](../repositories/gateway-service/README.md) |
| Auth | [../repositories/auth-service/README.md](../repositories/auth-service/README.md) |
| Authz | [../repositories/authz-service/README.md](../repositories/authz-service/README.md) |
| User | [../repositories/user-service/README.md](../repositories/user-service/README.md) |
| Block | [../repositories/editor-service/README.md](../repositories/editor-service/README.md) |
| Redis | [../repositories/redis-service/README.md](../repositories/redis-service/README.md) |
| Monitoring | [../repositories/monitoring-service/README.md](../repositories/monitoring-service/README.md) |

## 사용 방법
1. 먼저 이 디렉토리에서 공통 원칙을 확인한다.
2. 서비스별 README로 이동해 해당 서비스가 직접 소유하는 API를 확인한다.
3. request/response 세부 shape은 `artifacts/openapi`의 YAML을 확인한다.
4. 공통 규칙과 서비스 문서가 충돌하면 common 문서를 먼저 정리한 뒤 서비스 문서를 맞춘다.
