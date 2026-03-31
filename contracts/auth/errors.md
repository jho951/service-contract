# Auth Error Contract

## Error Code Range
- `9000~9099`: auth-service 전용 계약/연동 오류
- `9100~9199`: 인증, 토큰, 세션, upstream 오류

## Main Errors
| HTTP Status | Code | Message | Meaning |
| :---: | :--- | :--- | :--- |
| 400 | 9015 | 잘못된 요청입니다. | 요청 형식 또는 파라미터 오류 |
| 400 | 9016 | 요청 필드 유효성 검사에 실패했습니다. | validation 실패 |
| 405 | 9017 | 허용되지 않은 HTTP 메서드입니다. | method not allowed |
| 404 | 9002 | 요청하신 URL을 찾을 수 없습니다. | auth route not found |
| 400 | 9003 | 데이터 저장 실패, 재시도 혹은 관리자에게 문의해주세요. | internal persistence failure |
| 409 | 9005 | 이미 존재하는 인증 계정입니다. | auth account conflict |
| 404 | 9006 | 인증 계정을 찾을 수 없습니다. | auth account not found |
| 502 | 9007 | user-service 연동에 실패했습니다. | user-service upstream failure |
| 401 | 9101 | 인증이 필요합니다. | unauthenticated |
| 403 | 9102 | 접근이 허용되지 않습니다. | forbidden |
| 429 | 9103 | 요청이 너무 많습니다. | rate limit |
| 413 | 9104 | 요청 본문이 허용 크기를 초과했습니다. | payload too large |
| 504 | 9105 | 업스트림 응답 시간이 초과되었습니다. | upstream timeout |
| 502 | 9106 | 업스트림 호출에 실패했습니다. | upstream failure |
| 401 | 9111 | 유효하지 않은 인증 토큰입니다. | invalid token |
| 401 | 9112 | 인증 토큰이 만료되었습니다. | expired token |
| 401 | 9113 | 로그인이 필요한 요청입니다. | login required |
| 400 | 9999 | 요청 응답 실패, 관리자에게 문의해주세요. | fallback failure |

## Contract Notes
- auth-service는 `GlobalResponse` envelope와 위 코드 범위를 사용한다.
- Gateway는 외부 실패를 표준화할 수 있으나, 내부 운영 문서에서는 auth-service 코드 원형을 기준으로 기록한다.
