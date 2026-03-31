# User API Contract

## Base Paths
- Public/Gateway-facing: `/users`
- Internal: `/internal/users`

## Public APIs

### `POST /users/signup`
- Request: `email`
- Response: `GlobalResponse<UserCreateResponse>`

### `GET /users/me`
- 인증 주체는 Gateway 재주입 컨텍스트 또는 JWT다.
- Response: `GlobalResponse<UserDetailResponse>`

## Internal APIs

### `POST /internal/users`
### `POST /internal/users/social`
### `POST /internal/users/ensure-social`
### `POST /internal/users/find-or-create-and-link-social`
### `PUT /internal/users/{userId}/status`
### `GET /internal/users/{userId}`
### `GET /internal/users/by-email`
### `GET /internal/users/by-social`
- 내부 사용자 생성, 소셜 연결, 상태 변경, 조회를 다룬다.
- `ensure-social`과 `find-or-create-and-link-social`은 동일 계열의 표준 흐름이다.

## Response Models
- `UserDetailResponse`
  - `id`
  - `email`
  - `role`
  - `status`
  - `createdAt`
  - `updatedAt`
  - `userSocialList`
- `UserSocialResponse`
  - `id`
  - `userId`
  - `provider`
  - `providerUserId`
  - `email`
  - `socialType`
  - `providerId`
- `UserCreateResponse`
  - `user`

## Contract Notes
- 모든 성공 응답은 `GlobalResponse` envelope를 사용한다.
- `SuccessCode`는 HTTP status와 비즈니스 성공 코드를 함께 정의한다.
- 공개 API 노출 여부는 기능 플래그로 제어될 수 있다.
