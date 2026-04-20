# User Error Contract

## Error Code Range
- `7000~7099`: 공통 인프라/검증 오류
- `7100~7199`: 사용자 도메인 오류
- `7200~7299`: JWT/보안 설정 오류

## Main Errors
| HTTP Status | Code | Message | Meaning |
| :---: | :--- | :--- | :--- |
| 400 | 7000 | 잘못된 요청입니다. | bad request |
| 400 | 7001 | 요청 필드 유효성 검사에 실패했습니다. | validation failure |
| 405 | 7002 | 허용되지 않은 HTTP 메서드입니다. | method not allowed |
| 401 | 7003 | 인증이 필요합니다. | unauthorized |
| 403 | 7004 | 접근 권한이 없습니다. | forbidden |
| 404 | 7005 | 리소스를 찾을 수 없습니다. | not found |
| 500 | 7099 | 서버 오류가 발생했습니다. | internal server error |
| 404 | 7100 | 사용자를 찾을 수 없습니다. | user not found |
| 400 | 7101 | 이미 사용 중인 이메일입니다. | email conflict |
| 400 | 7102 | 이미 연결된 소셜 계정입니다. | social conflict |
| 400 | 7200 | 비밀키가 비어있습니다. | missing secret |
| 401 | 7201 | 최소 32바이트 이상의 문자열이여야합니다. | invalid secret |
| 401 | 7202 | 유효하지 않은 토큰입니다. | invalid token |

## Contract Notes
- user-service는 `GlobalResponse` envelope와 위 코드 범위를 사용한다.
- public API와 internal API는 같은 에러 체계를 공유하되, 노출 범위는 Gateway 정책에 따라 제한될 수 있다.
