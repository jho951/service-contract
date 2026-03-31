# Authz Cache Contract

이 문서는 권한 캐시와 무효화 전략을 정의한다.

## 기본 원칙
- 권한 캐시는 성능용이며, 권한의 진실은 아니다.
- 캐시는 version key와 TTL을 함께 사용한다.
- 위험도가 높은 권한일수록 TTL을 짧게 잡는다.

## 키 예시
```text
authz:decision:{userId}:{resourceType}:{resourceId}:{action}:{authzVersion}
authz:roles:{userId}:{workspaceId}:{membershipVersion}
authz:delegation:{userId}:{resourceType}:{resourceId}:{delegationVersion}
```

## TTL 권장
| Category | TTL |
| --- | --- |
| read | 30s~2m |
| edit | 10s~30s |
| share/admin/delegation | very short or no cache |

## 무효화 이벤트
- role grant/revoke
- policy update
- delegation change
- membership change
- page lock/unlock
- visibility change
- tenant suspension

## 정책
- TTL만으로 권한 회수 지연을 막지 못하므로 이벤트 무효화를 함께 써야 한다.
- negative cache는 짧게 유지한다.
