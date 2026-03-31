# Redis Security Contract

## Trust Boundary
| 항목 | 설명 |
| --- | --- |
| 외부 접근 | 클라이언트는 Redis에 직접 접근하지 않는다. |
| 네트워크 경계 | Redis는 내부 서비스 네트워크에서만 접근한다. |
| 인증 | Redis 비밀번호/ACL은 운영 환경에서 설정한다. |

## Access Policy
| 정책 | 설명 |
| --- | --- |
| read/write ownership | 각 서비스는 자기 prefix만 사용한다. |
| destructive commands | `FLUSHALL`, `CONFIG SET`, `KEYS` 같은 전역 명령은 운영 절차로 제한한다. |
| TTL policy | 캐시성 키는 TTL 없이 저장하지 않는다. |

## Failure Policy
| 상황 | 정책 |
| --- | --- |
| session cache 실패 | Gateway는 인증 정책에 따라 계속 진행하거나 거부한다. |
| permission cache 실패 | Gateway는 관리자 경로를 fail-closed로 처리한다. |
| authz-service 보조 캐시 실패 | Authz-server는 DB 정책을 우선한다. |

## Audit and Operations
| 항목 | 설명 |
| --- | --- |
| 접근 추적 | Redis 접속 실패와 인증 실패는 운영 로그에 남긴다. |
| secret management | Redis password는 repo에 저장하지 않는다. |
| shared network | 서비스 간 접근은 공용 backbone 네트워크를 사용한다. |
