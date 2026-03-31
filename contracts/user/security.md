# User Security Contract

## Trust Boundary
- 공개 API는 Gateway를 경유하는 것을 기본으로 한다.
- 내부 API는 Gateway 또는 신뢰 가능한 내부 네트워크에서만 사용한다.
- 외부에서 주입된 `X-User-Id`는 신뢰하지 않는다.

## Authentication
- `GET /users/me` 는 JWT 또는 Gateway 재주입 사용자 컨텍스트를 사용한다.
- 내부 사용자 조회/수정 API는 Gateway가 재주입한 사용자 식별 정보를 기준으로 접근한다.

## Authorization
- 공개 회원가입은 인증 없이도 호출 가능하다.
- 내부 사용자 생성, 상태 변경, 소셜 연동 API는 내부 전용이다.
- 공개 사용자 API 노출 여부는 기능 플래그로 제어할 수 있다.
- `users/me` 는 활성 사용자만 허용한다.
- 사용자 프로필에서 권한 보유 사실을 공개할지 여부는 별도의 visibility/privacy 정책으로 다룬다.
- `Authz-server`의 capability 판정 결과와 `User-server`의 공개 범위 정책은 분리해서 해석한다.

## Data Integrity
- 사용자 상태 변경은 승인된 내부 호출에 한정한다.
- 소셜 연동 요청은 이메일, socialType, providerId 조합의 정합성을 검증해야 한다.
- 동일 사용자에 대한 중복 연동/생성은 멱등적으로 처리해야 한다.
