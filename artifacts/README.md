# Artifacts

`artifacts`는 기계가 읽는 계약 산출물을 담는다.

## Layout
| Directory | Purpose |
| --- | --- |
| [openapi](openapi) | OpenAPI YAML |
| [schemas](schemas) | JSON Schema |

## Rules
- 사람이 읽는 repository별 설명은 [repositories](../repositories/README.md)에 둔다.
- 공통 envelope, header, security 원칙은 [shared](../shared/README.md)에 둔다.
- 서비스가 소비하는 artifact 경로는 `contract.lock.yml`의 `consumes`에 명시한다.
