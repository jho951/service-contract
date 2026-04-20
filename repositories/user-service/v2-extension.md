# User V2 Extension

이 문서는 `user-service`의 현재 v1 계약을 대체하는 것이 아니라, v2로 확장될 수 있는 축을 정리한다.

## 범위
- 새 API 추가
- 사용자 상태/권한/소셜 제공자 확장
- 소셜 연동 로직 확장
- 보안 정책 확장
- 사용자 프로필 필드 확장
- 관측 지표 추가
- 예외/에러 범위 확장

## 1. API 확장
- 공개 API는 `app/src/main/java/com/api/user/controller/UserController.java` 기준으로 확장한다.
- 내부 연동 API는 `app/src/main/java/com/api/user/controller/InternalUserController.java` 기준으로 확장한다.
- `features.public-user-api.enabled`, `features.internal-user-api.enabled` 토글은 새 엔드포인트 추가를 쉽게 한다.
- 새 경로를 추가할 때는 `SecurityConfig`에 경로별 정책을 함께 붙인다.

## 2. 유스케이스 확장
- 실제 비즈니스 로직은 `UserServiceImpl` 계열에 모인다.
- v2 확장은 서비스 메서드를 먼저 추가하고 컨트롤러를 연결하는 방식이 자연스럽다.
- 서비스가 비대해지면 유스케이스 단위로 분리하는 리팩터링이 필요하다.

## 3. 사용자 모델 확장
- 사용자 상태는 `UserStatus`
- 소셜 제공자 타입은 `UserSocialType`
- 권한은 `UserRole`
- enum 확장은 DB 코드값, JSON 변환, 마이그레이션을 함께 맞춰야 한다.

## 4. 보안 확장
- 내부/외부 접근 정책은 `SecurityConfig`
- 상태/스코프 판단은 `JwtAccessPolicy`
- `/users/**` 와 `/internal/**` 경로 분리는 유지하고, 새 경로도 동일한 방식으로 정책을 붙인다.
- 프로필 가시성/개인정보 공개 범위는 별도 visibility/privacy 정책으로 분리한다.
- capability truth는 `authz-service`, 공개 여부는 `user-service`, 실제 기능 집행은 소비자 서비스가 담당한다.

## 5. 데이터 모델 확장
- 사용자 본체는 `User`
- 소셜 계정은 `UserSocial`
- 저장소는 `UserRepository`, `UserSocialRepository`
- 새 필드나 연관관계는 엔티티, repository, 마이그레이션을 함께 갱신해야 한다.

## 6. 응답/요청 확장
- 요청 DTO는 `UserRequest`
- 응답 DTO는 `UserResponse`
- 새 필드는 DTO와 계약 문서를 동시에 갱신한다.

## 7. 관측성 확장
- 소셜 연동 지표는 `SocialLinkMetrics`
- 요청, 충돌, 생성, 기존값 재사용, latency 축을 유지한다.
- 새 기능도 동일한 메트릭 축으로 붙인다.

## 8. 예외/에러 확장
- 전역 예외는 `GlobalExceptionHandler`
- 새 비즈니스 에러는 `ErrorCode`와 함께 추가한다.
- 에러 코드는 계약 문서의 `user/errors.md`와 일치해야 한다.

## 9. 계약/배포 연동
- 외부 API 변경은 contract 레포와 gateway 경로를 함께 본다.
- README의 Contract Source와 `contract.lock.yml`을 항상 최신화한다.

## v1과 v2의 관계
- v1은 현재 공개/내부 user API와 `GlobalResponse` envelope를 의미한다.
- v2는 확장 가능한 서비스 내부 축을 뜻하며, breaking change가 아니면 별도 전환 문서로 관리한다.
- 실제로 v2 API를 노출할 때만 OpenAPI와 `contract.lock.yml`을 갱신한다.
