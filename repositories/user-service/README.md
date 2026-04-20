# User Contract

User-service는 사용자 프로필, 상태, 소셜 연결, visibility/privacy 정책을 소유한다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/user-service |
| Branch | `main` |
| Contract Lock | `contract.lock.yml` |

## 책임 경계
| 영역 | 책임 |
| --- | --- |
| Public user API | signup, current user profile |
| Internal user API | Auth-service/Gateway 연동용 사용자 생성/조회/상태 변경 |
| Social account | social profile 생성, 보장, 연결, 조회 |
| Visibility/privacy | 프로필과 권한 정보의 공개 여부 |
| Response envelope | User-service public/internal 응답 envelope |

## 현재 API 범위
| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/users/signup` | 공개 회원가입 |
| `GET` | `/users/me` | 현재 사용자 조회 |
| `POST` | `/internal/users` | 내부 사용자 생성 |
| `POST` | `/internal/users/social` | 소셜 사용자 생성 |
| `POST` | `/internal/users/ensure-social` | 소셜 사용자 보장 |
| `POST` | `/internal/users/find-or-create-and-link-social` | 소셜 사용자 찾기/생성/연결 |
| `PUT` | `/internal/users/{userId}/status` | 사용자 상태 변경 |
| `GET` | `/internal/users/{userId}` | user id 조회 |
| `GET` | `/internal/users/by-email` | email 조회 |
| `GET` | `/internal/users/by-social` | social key 조회 |

## 문서
- [API Contract](api.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Error Contract](errors.md)
- [Visibility & Privacy Contract](visibility.md)
- [V2 Extension](v2-extension.md)
- [Common Audit Contract](../../shared/audit.md)
- [User Service OpenAPI](../../artifacts/openapi/user-service.v1.yaml)

## 계약 원칙
- 공개 사용자 API는 Gateway 경유를 기본으로 한다.
- 내부 사용자 API는 내부 JWT 또는 internal secret 같은 명시된 신뢰 수단을 요구한다.
- `X-User-Id`는 Gateway가 재주입한 값만 신뢰한다.
- 권한의 진실은 Authz-service가 소유한다.
- 권한 정보를 프로필에 공개할지 여부는 User-service visibility/privacy 정책이 소유한다.
- 실제 기능 실행은 소비자 서비스가 자기 도메인에서 강제한다.
