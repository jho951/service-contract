# User Contract

`User-server`의 서비스 계약 허브다.

## 서비스 책임
- 공개 사용자 가입
- 현재 사용자 정보 조회
- 내부 사용자 생성, 상태 변경, 조회
- 소셜 계정 생성, 보장, 연결, 조회
- 사용자 프로필 가시성, 개인정보 공개 범위, 권한 노출 정책
- 공개/내부 API의 응답 envelope 관리

## 세부 문서
- [API Contract](api.md)
- [Security Contract](security.md)
- [Operations Contract](ops.md)
- [Error Contract](errors.md)
- [Visibility & Privacy Contract](visibility.md)
- [V2 Extension](v2-extension.md)
- [User Service OpenAPI](../openapi/user-service.v1.yaml)

## API 범위
- `POST /users/signup`
- `GET /users/me`
- `POST /internal/users`
- `POST /internal/users/social`
- `POST /internal/users/ensure-social`
- `POST /internal/users/find-or-create-and-link-social`
- `PUT /internal/users/{userId}/status`
- `GET /internal/users/{userId}`
- `GET /internal/users/by-email`
- `GET /internal/users/by-social`

## 계약 원칙
- 공개 사용자 API는 Gateway 경유를 기본으로 한다.
- 내부 사용자 API는 Gateway가 재주입한 내부 JWT와 사용자 컨텍스트를 신뢰한다.
- `X-User-Id`는 내부 사용자 식별의 표준 입력이다.
- 소셜 연동, 상태 변경, 내부 조회는 user-service의 내부 계약으로 분리 관리한다.
- 공개 API는 `features.public-user-api.enabled` 에 의해 노출을 제어할 수 있다.
- 권한의 진실은 `Authz-server`가, 권한의 공개 여부는 `User-server`가, 실제 기능 집행은 소비자 서비스가 담당한다.
