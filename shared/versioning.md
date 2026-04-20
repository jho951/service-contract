# Versioning Policy

이 정책은 계약 변경과 public API route versioning을 분리해서 관리한다.

## Contract Version
계약 릴리즈는 Semantic Versioning을 따른다.

| Version part | Meaning |
| --- | --- |
| `MAJOR` | breaking contract change |
| `MINOR` | backward compatible extension |
| `PATCH` | 문서 보완, 오타, 비기능 수정 |

릴리즈 태그 예시:
```txt
service-contract-v1.2.0
```

릴리즈에는 다음을 남긴다.
- 변경 요약
- 영향 서비스
- migration 필요 여부
- 검증 결과

## Public Route Version
Public API route version은 Gateway가 소유한다.

| Public version | Owner | Meaning |
| --- | --- | --- |
| `/v1/**` | Gateway | 현재 안정 public API |
| `/v2/**` | Gateway | breaking 또는 큰 기능 확장용 public API |

Backend service는 기본적으로 public version prefix를 직접 구현하지 않는다.

Example:
```txt
Client:  POST /v1/auth/login
Gateway: POST /auth/login  -> Auth-service
```

## Upstream Version
서비스 내부 upstream route는 최대한 안정적으로 유지한다.

Upstream versioning은 다음 조건일 때만 도입한다.
- 같은 서비스가 동시에 두 개의 incompatible upstream contract를 제공해야 한다.
- Gateway rewrite만으로 호환이 어렵다.
- DTO, cookie, session semantics가 같은 endpoint 안에서 분기하기 어렵다.

도입 시 별도 문서에 명시한다.

```txt
repositories/<repo>/api.md
repositories/<repo>/v2.md
artifacts/openapi/<service>.v2.yaml
```

## Draft Policy
미래 기능은 현재 구현처럼 쓰지 않는다.

| 상태 | 의미 |
| --- | --- |
| `current` | 현재 구현과 맞는 계약 |
| `draft` | 설계 중이며 구현 보장 없음 |
| `planned` | 구현 예정이지만 아직 public contract 아님 |
| `deprecated` | 유지 중이나 제거 예정 |

## Lock Rule
서비스 레포는 구현 완료 후 자기 `contract.lock.yml`에 다음을 고정한다.
- 참조한 contract ref
- 참조한 contract commit SHA
- 서비스가 소비하는 계약 문서/OpenAPI 목록
- CI에서 수행할 계약 검증 항목

테스트와 스모크 결과는 PR 본문과 CI 실행 기록에 남긴다.
