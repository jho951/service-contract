# Example: OAuth2 Social Provisioning

## Gateway External Call
- `POST /v1/internal/users/find-or-create-and-link-social`
- Header: `X-Internal-Request-Secret: <shared-secret>`

## Gateway -> User Internal Call
- `POST /internal/users/find-or-create-and-link-social`
- Header: `Authorization: Bearer <internal-jwt>`

## Request Body
```json
{
  "email": "user@example.com",
  "provider": "GITHUB",
  "providerUserId": "1234567890"
}
```

## Expected
- 기존 링크 있으면 existing 반환
- 없으면 사용자 생성/링크 후 created 반환
- `userId`, `role`, `status` 포함 응답
