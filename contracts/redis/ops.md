# Redis Operations Contract

## Startup / Runtime
| 항목 | 값 |
| --- | --- |
| 역할 | 중앙 캐시/세션 저장 계층 |
| 포트 | `6379` |
| 프로토콜 | Redis TCP |

## Operational Responsibilities
| 책임 | 설명 |
| --- | --- |
| health | 인스턴스 alive 상태 확인 |
| readiness | 인증/replication/스토리지 준비 상태 확인 |
| TTL enforcement | 캐시 키 만료 관리 |
| connection stability | 다수 서비스의 짧은 요청을 안정적으로 처리 |

## Validation
| 검증 | 예시 |
| --- | --- |
| ping | `redis-cli -h <host> -p 6379 PING` |
| auth | `redis-cli -h <host> -p 6379 -a <password> PING` |
| key check | `redis-cli -h <host> -p 6379 KEYS 'gateway:*'` |

## Maintenance
| 항목 | 설명 |
| --- | --- |
| backup | persistence 정책에 따라 스냅샷/appendonly를 관리한다. |
| eviction | cache TTL에 맞는 eviction 정책을 유지한다. |
| prefix contract | 새 캐시 키 prefix는 계약 레포에 먼저 추가한다. |

## Notes
| 원칙 | 설명 |
| --- | --- |
| direct access | 운영/디버그 목적의 직접 접근은 제한적으로만 허용한다. |
| service coupling | Redis 장애 시 각 서비스의 fail-open/fail-closed는 서비스 contract가 결정한다. |
