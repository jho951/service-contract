# Redis Contract

Redis는 HTTP API를 노출하지 않는 중앙 cache/session 저장 계층이다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/redis-service |
| Branch | `main` |
| Contract Lock | `contract.lock.yml` |

## 책임 경계
| 영역 | 책임 |
| --- | --- |
| Key namespace | 서비스별 prefix 충돌 방지 |
| TTL policy | session/cache 만료 정책 |
| Gateway cache | session/admin decision cache 저장 |
| Auth/Authz support | refresh/session/policy 보조 저장 |
| Monitoring integration | Redis exporter와 memory/connection/eviction 관측 기준 |
| Operations | 연결, 인증, ready 상태 유지 |

## 문서
- [Keys Contract](keys.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Common Audit Contract](../../shared/audit.md)

## OpenAPI
- Redis는 HTTP API를 노출하지 않으므로 `artifacts/openapi`에 Redis 전용 OpenAPI YAML을 두지 않는다.

## 주요 prefix
| Prefix | Owner |
| --- | --- |
| `gateway:session:` | Gateway |
| `gateway:admin-authz:` | Gateway |
| `permission:*` | Authz-service |

## 계약 원칙
- 각 서비스는 자기 key prefix만 소유한다.
- Redis 장애는 cache/storage 실패로 취급하고, fail-open/fail-closed는 소비 서비스가 결정한다.
- 외부 client는 Redis에 직접 접근하지 않는다.
- 모니터링은 `redis-cli PING`만으로 끝내지 않고 exporter 지표와 소비 서비스의 Redis dependency 지표를 함께 본다.
- 운영자 수준 key 조작은 감사 대상이다.
- 현재 구현 repo의 compose project 이름은 `redis-server-dev`, `redis-server-prod`다.
- 현재 구현 service key는 `redis-server`이고, shared network alias는 `redis`다.
- repo 이름은 `redis-service`지만, 실제 런타임 이름은 `redis-server` service key와 `redis` shared alias를 기준으로 맞춘다.

## 운영 배포 자산

- EC2 image-only 배포 기준 산출물은 구현 repo의 `deploy/ec2/` 아래에 둔다.
- 기본 파일은 `docker-compose.yml`, `.env.production.example`, `README.md`다.
