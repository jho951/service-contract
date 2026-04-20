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
| Operations | 연결, 인증, ready 상태 유지 |

## 문서
- [Keys Contract](keys.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Common Audit Contract](../../shared/audit.md)

## 주요 prefix
| Prefix | Owner |
| --- | --- |
| `gateway:session:` | Gateway |
| `gateway:admin-permission:` | Gateway |
| `permission:*` | Authz-service |

## 계약 원칙
- 각 서비스는 자기 key prefix만 소유한다.
- Redis 장애는 cache/storage 실패로 취급하고, fail-open/fail-closed는 소비 서비스가 결정한다.
- 외부 client는 Redis에 직접 접근하지 않는다.
- 운영자 수준 key 조작은 감사 대상이다.
