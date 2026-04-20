# Authentication Channel Policy

## 목적
Gateway가 요청 유형을 판별해 하이브리드 인증 수단을 일관되게 선택하도록 한다.

## 1) 라우트 성격 판정
- `PROTECTED` / `ADMIN` 라우트에서만 인증 선검사를 수행한다.
- `PUBLIC` / `INTERNAL` 라우트는 별도 정책을 따른다.
- 라우트 성격은 Gateway가 먼저 판단하고, 그 다음 인증 채널을 선택한다.
- `ADMIN` 라우트는 인증 성공 후 Authz 인가 판정을 추가로 받는다.

## 2) 클라이언트 판별 우선순위
1. `X-Client-Type` 같은 명시 헤더
2. `Origin` / `Referer` 기반 브라우저 판정
3. `User-Agent` 보조 판정
4. endpoint 단위 예외 처리

## 권장 클라이언트 타입
- `web`: 브라우저 앱
- `native`: 모바일 앱
- `cli`: CLI / 스크립트
- `api`: 외부 연동 / 서버간 호출

## 구현 기준 판별값
- `X-Client-Type`은 다음 별칭을 허용한다.
  - `web`, `browser`
  - `native`, `mobile`, `app`, `desktop`
  - `cli`
  - `api`, `service`, `server`
- `X-Client-Type` 값이 있지만 허용되지 않으면 Gateway는 `400 / 1002`로 거절한다.
- 명시 헤더, Origin, Referer, User-Agent, endpoint 규칙으로도 채널을 정할 수 없으면 `400 / 1001`로 거절한다.
- 현재 구현에서는 `PROTECTED` / `ADMIN` 라우트의 endpoint fallback이 `web`으로 고정되어 있다.
- 따라서 `400 / 1001`은 정책상 유지되는 코드이지만, 현재 구현에서는 사실상 예약 코드에 가깝다.

## 3) 채널별 인증 수단 고정
### web 판정
- `Cookie` 기반 세션을 우선 사용한다.
- `ACCESS_TOKEN` 쿠키가 있으면 먼저 Bearer 검증 경로로 사용한다.
- `ACCESS_TOKEN`이 없으면 `sso_session` 쿠키로 세션 검증을 수행한다.
- 브라우저 요청에서 `Authorization`이 함께 오더라도, web 판정이면 Cookie 계열이 우선이다.

### non-web 판정
- `Authorization: Bearer <token>`을 우선 사용한다.
- Cookie는 보조 신호로만 취급한다.
- Gateway는 인증 성공 시 내부 JWT를 `Authorization`으로 재주입하고, 외부 `Authorization`은 제거한다.

### 둘 다 존재하는 경우
- `web` 판정이면 Cookie를 선택한다.
- `native` / `cli` / `api` 판정이면 Bearer를 선택한다.

## 4) Gateway 정규화 규칙
- 인증 성공 후 Gateway는 내부용 `X-User-Id`로 정규화한다.
- 인증 성공 후 Gateway는 내부용 `X-User-Status`와 `X-Client-Type`도 재주입한다.
- 외부에서 들어온 `X-User-Id`는 제거하고 신뢰하지 않는다.
- 내부 서비스는 `X-User-Id`만 신뢰한다.
- 내부 서비스는 Cookie나 Bearer를 직접 신뢰하지 않는다.
- 내부 서비스는 Gateway가 재주입한 `Authorization`만 검증한다.

## 문서화된 호출 규약
### 브라우저용 호출 규약
- Cookie 기반 세션 사용
- `Authorization`은 보내지 않아도 된다
- `X-Client-Type: web` 권장
- Gateway는 Cookie를 우선 인증 수단으로 사용한다

### 비브라우저용 호출 규약
- `Authorization: Bearer <token>` 사용
- Cookie 의존 금지
- `X-Client-Type: native|cli|api` 권장
- Gateway는 Bearer를 우선 인증 수단으로 사용한다

### 공통 규약
- 외부에서 들어온 `X-User-Id`는 무시한다
- 인증 성공 후에만 Gateway가 내부 `X-User-Id`를 재주입한다
- 내부 서비스는 `X-User-Id`만 신뢰한다

## 테스트 매트릭스
- Cookie 기반 성공
  - `Cookie: ACCESS_TOKEN=...`만으로 성공
  - `Cookie: sso_session=...`만으로 성공
- Bearer 기반 성공
  - `Authorization: Bearer ...`만으로 성공
- 둘 다 있는 경우 우선순위
  - `X-Client-Type: web` + Cookie + Bearer => Cookie 선택
  - `X-Client-Type: native` + Cookie + Bearer => Bearer 선택
- 실패 케이스
  - `X-Client-Type`이 허용되지 않은 값인 경우
  - Bearer만 있고 토큰 형식 불일치
  - 채널 판정이 안 되는 경우 `400 / 1001` (현재 구현에서는 거의 발생하지 않음)
  - 인증 수단이 없으면 `401 / 1003`
