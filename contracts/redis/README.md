# Redis Contract

`Redis` 서비스 계약 허브다.

## 책임
| 책임 | 범위 |
| --- | --- |
| 중앙 캐시 저장 | Gateway / Authz / Auth 세션 및 권한 캐시 저장 |
| TTL 관리 | 짧은 TTL 기반 캐시 만료 |
| 단순 키-값 저장 | service-specific value 저장 |
| 운영 안정성 | 연결/인증/ready 상태 유지 |

## 문서
- [Keys Contract](keys.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)

## API
Redis는 HTTP API를 노출하지 않는다.

## 계약 원칙
| 원칙 | 설명 |
| --- | --- |
| 키 소유권 | 각 서비스는 자기 키 prefix만 소유한다. |
| 실패 전략 | Redis 장애는 캐시 실패로만 취급하고, 각 서비스는 자체 정책으로 fail-open/fail-closed를 결정한다. |
| 운영 경계 | 외부 클라이언트는 Redis에 직접 접근하지 않는다. |
