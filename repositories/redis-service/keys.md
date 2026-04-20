# Redis Keys Contract

## Key Namespace
| Prefix | Owner | Purpose |
| --- | --- | --- |
| `gateway:session:` | Gateway | Bearer/session auth 성공 결과 캐시 |
| `gateway:admin-permission:` | Gateway | 관리자 경로 허용/거부 캐시 |
| `permission:*` | authz-service | 권한/역할/정책 보조 캐시 |

## Key Rules
| 규칙 | 설명 |
| --- | --- |
| namespace isolation | 서비스는 자기 prefix만 읽고 쓴다. |
| TTL required | 캐시성 키는 TTL을 반드시 둔다. |
| value shape | 값 포맷은 서비스별 contract에만 문서화한다. |
| flush safety | 운영 중 `FLUSHALL` 같은 전역 삭제는 사용하지 않는다. |

## Gateway Keys
| Key | Value | TTL |
| --- | --- | --- |
| `gateway:session:<hash>` | `AuthResult` 인코딩 | `GATEWAY_SESSION_CACHE_TTL_SECONDS` |
| `gateway:admin-permission:<hash>` | `ALLOW` / `DENY` | `GATEWAY_PERMISSION_CACHE_TTL_SECONDS` |

## Authz Keys
| Key | Value | TTL |
| --- | --- | --- |
| `permission:role-policy:<role>` | role policy snapshot | service defined |
| `permission:path-policy:<path>` | path policy snapshot | service defined |
| `permission:audit:<requestId>` | audit helper entry | service defined |

## Contract Notes
| 원칙 | 설명 |
| --- | --- |
| 해시 사용 | Gateway는 session token과 admin permission 판단에 해시 기반 키를 사용한다. |
| 키 충돌 방지 | prefix는 서비스별로 분리한다. |
| 포맷 비공개 | 세부 value encoding은 각 서비스 contract에 둔다. |
