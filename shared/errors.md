# Common Error Contract

모든 서비스의 실패 응답은 같은 기본 envelope를 따른다. 서비스마다 code range는 달라도, client와 Gateway가 읽는 기본 필드는 같아야 한다.

## Error Envelope
```json
{
  "httpStatus": 401,
  "success": false,
  "code": 9101,
  "message": "인증이 필요합니다.",
  "data": null
}
```

| Field | Required | Type | Meaning |
| --- | --- | --- | --- |
| `httpStatus` | yes | integer | HTTP status code |
| `success` | yes | boolean | error response에서는 항상 `false` |
| `code` | yes | string or integer | 서비스/도메인별 error code |
| `message` | yes | string | 사람이 읽을 수 있는 실패 메시지 |
| `data` | no | any JSON value | validation detail, field error, debug-safe context |

기계 검증용 schema는 [../artifacts/schemas/error-envelope.schema.json](../artifacts/schemas/error-envelope.schema.json)에 둔다.

## Service Error Documents
| Service | Document |
| --- | --- |
| Gateway | [../repositories/gateway-service/errors.md](../repositories/gateway-service/errors.md) |
| Auth | [../repositories/auth-service/errors.md](../repositories/auth-service/errors.md) |
| Authz | [../repositories/authz-service/errors.md](../repositories/authz-service/errors.md) |
| User | [../repositories/user-service/errors.md](../repositories/user-service/errors.md) |
| Block | [../repositories/editor-service/errors.md](../repositories/editor-service/errors.md) |

## Gateway Normalization
Gateway는 upstream 에러를 public API 응답으로 표준화할 수 있다. 다만 운영 로그와 서비스별 troubleshooting에서는 upstream 서비스의 원형 `code`를 보존해야 한다.

## Rules
- `success`는 실패 응답에서 반드시 `false`다.
- `httpStatus`와 실제 HTTP status는 가능하면 일치해야 한다.
- `message`는 사용자 또는 운영자가 이해할 수 있는 문장이어야 한다.
- 민감 정보, token, password, secret은 `message`나 `data`에 포함하지 않는다.
- 서비스별 code range는 서비스별 `errors.md`에서 관리한다.
