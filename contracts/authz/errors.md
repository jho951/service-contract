# Authz Error Contract

## Error Code Range
- 이 서비스는 별도 `code` 필드를 노출하지 않고 HTTP status + `message`를 반환한다.

## Main Errors
| HTTP Status | Code | Message | Meaning |
| :---: | :--- | :--- | :--- |
| 400 | - | X-User-Id 헤더가 필요합니다. | 요청 헤더 누락 |
| 400 | - | X-User-Role 헤더가 필요합니다. | 요청 헤더 누락 |
| 400 | - | X-Session-Id 헤더가 필요합니다. | 요청 헤더 누락 |
| 400 | - | X-Original-Method 헤더가 필요합니다. | 요청 헤더 누락 |
| 400 | - | X-Original-Path 헤더가 필요합니다. | 요청 헤더 누락 |
| 400 | - | 허용하지 않는 HTTP Method입니다. | method invalid |
| 400 | - | X-Original-Path는 '/'로 시작해야 합니다. | path format error |
| 400 | - | X-Original-Path에 '..'를 포함할 수 없습니다. | path traversal guard |
| 400 | - | X-Original-Path 형식이 잘못되었습니다. | path format error |
| 400 | - | X-User-Role 값이 올바르지 않습니다. | role header invalid |
| 403 | - | 응답 본문 없음 | denied |

## Contract Notes
- `PermissionErrorResponse`는 `400` 입력 오류에만 사용하며 단일 `message` 필드를 반환한다.
- Gateway는 외부 실패를 표준화할 수 있으나, 내부 운영 문서에서는 authz-service의 원문 메시지를 기준으로 기록한다.
