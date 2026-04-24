# Explain Page Contract

`Explain-page`는 Next.js 기반 프론트엔드로, 브라우저에서 `gateway-service`를 단일 인증/API 진입점으로 사용한다.
인증은 cookie 기반 세션을 전제로 하고, Gateway public `/v1/**` route를 소비한다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/Explain-page |
| Branch | `main` |
| Contract Lock | 현재 구현에는 `contract.lock.yml` 없음 |

## 현재 구현 기준
- `NEXT_PUBLIC_GATEWAY_BASE_URL` 또는 `NEXT_PUBLIC_SSO_BASE_URL`를 읽어 Gateway base URL을 만들고, 끝에 `/v1`가 없으면 자동으로 `/v1`를 붙인다.
- auth path 상수 기본값은 `/auth/sso/start`, `/auth/exchange`, `/auth/me`, `/auth/refresh`, `/auth/logout`처럼 `/v1` 없이 유지한다.
- 최종 URL 조립 시 `base=/v1` + `path=/auth/**` 조합으로 Gateway public auth API를 호출한다.
- fetch 호출은 `credentials: "include"`를 사용한다.

## 운영 배포 자산

- EC2 image-only 배포 기준 산출물은 구현 repo의 `deploy/ec2/` 아래에 둔다.
- 기본 파일은 `docker-compose.yml`, `.env.production.example`, `README.md`이고, host Nginx reverse proxy example을 함께 둔다.
- 현재 운영 bundle은 nginx 컨테이너 대신 host Nginx가 `127.0.0.1:3000` 앱 포트를 프록시하는 구성을 기본으로 둔다.

## URL 조립 규칙
Explain-page는 base URL과 path를 아래처럼 조합한다.

| 항목 | 현재 구현 |
| --- | --- |
| Base URL | `http://localhost:8080/v1` |
| Path style | `/auth/...`, `/users/...`, `/documents/...` |
| 최종 요청 예시 | `http://localhost:8080/v1/auth/me` |

예시:

```text
base = http://localhost:8080/v1
path = /auth/sso/start
final = http://localhost:8080/v1/auth/sso/start
```

이 구조에서는 path 상수에 `/v1`를 다시 넣으면 안 된다.

## 주요 소비 경로
| 목적 | 경로 |
| --- | --- |
| 로그인 시작 | `GET /v1/auth/sso/start` |
| ticket 교환 | `POST /v1/auth/exchange` |
| 현재 세션 | `GET /v1/auth/me` |
| session alias | `GET /v1/auth/session` |
| refresh | `POST /v1/auth/refresh` |
| logout | `POST /v1/auth/logout` |
| 사용자 정보 | `GET /v1/users/me` |
| 문서 API | `/v1/documents/**` |
| 에디터 작업 | `/v1/editor-operations/**` |
| 관리자 API | `/v1/admin/**` |

## 인증 흐름
현재 구현 기준 인증 흐름은 아래 순서를 따른다.

```text
Explain-page
  -> GET /v1/auth/sso/start
  -> Gateway/Auth OAuth
  -> /auth/callback
  -> POST /v1/auth/exchange
  -> GET /v1/auth/session
  -> redirect
  -> app bootstrap에서 GET /v1/auth/me
  -> 필요 시 POST /v1/auth/refresh 후 GET /v1/auth/session 또는 /v1/auth/me 재시도
  -> POST /v1/auth/logout
```

세션 전달 방식:

- 브라우저는 Gateway/Auth가 발급한 cookie를 자동 전송한다.
- fetch 호출은 `credentials: "include"`를 강제한다.
- local storage에는 auth 완료 여부 같은 보조 상태만 두고, 인증 자체의 source of truth로 쓰지 않는다.

경로 검증:

- client는 허용된 Gateway path prefix만 통과시킨다.
- `/auth/`, `/users/`, `/documents/`, `/editor-operations/`, `/admin/`, `/.well-known/jwks.json`, `/health`, `/ready`, `/error`만 조립 대상으로 인정한다.

## 환경 변수
- `NEXT_PUBLIC_GATEWAY_BASE_URL`
- `NEXT_PUBLIC_SSO_BASE_URL`
- `NEXT_PUBLIC_GATEWAY_AUTH_LOGIN_PAGE`
- `NEXT_PUBLIC_START_FRONTEND_URL`
- `NEXT_PUBLIC_SSO_CONSUMER_CALLBACK_URL`

### 권장값
| 변수 | 권장값 | 설명 |
| --- | --- | --- |
| `NEXT_PUBLIC_GATEWAY_BASE_URL` | `http://localhost:8080` | 코드가 내부적으로 `/v1`를 붙인다 |
| `NEXT_PUBLIC_SSO_BASE_URL` | `http://localhost:8080` | Gateway base URL 대체용 |
| `NEXT_PUBLIC_GATEWAY_AUTH_LOGIN_PAGE` | `explain` | Gateway/Auth가 login page 문맥을 구분할 때 사용 |
| `NEXT_PUBLIC_START_FRONTEND_URL` | `http://localhost:3000` | explain-page 자체 origin |
| `NEXT_PUBLIC_SSO_CONSUMER_CALLBACK_URL` | `http://localhost:3000/auth/callback` | OAuth callback 절대 URL |

## 로컬 개발 전제
- explain-page 기본 포트는 `3000`이다.
- Gateway 기본 포트는 `8080`이다.
- `NEXT_PUBLIC_GATEWAY_BASE_URL`에 `/v1`가 이미 붙어 있어도 코드는 중복 추가를 피한다.
- callback 이후 `ticket -> /v1/auth/exchange -> /v1/auth/session -> redirect` 순서로 세션을 확정한다.

## 자주 틀리는 설정
### 1. path 상수에 `/v1`를 다시 넣는 경우
잘못된 예:

```text
base = http://localhost:8080/v1
path = /v1/auth/me
```

이 경우 최종 URL은 `/v1/v1/auth/me`가 된다.

### 2. cookie 없이 호출하는 경우
- `credentials: "include"`가 빠지면 Gateway session/cookie 기반 인증이 동작하지 않는다.

### 3. callback URL이 프론트 origin과 다른 경우
- `NEXT_PUBLIC_SSO_CONSUMER_CALLBACK_URL`이 실제 FE origin과 다르면 OAuth callback 이후 exchange 흐름이 어긋난다.

## 구현 메모
- current 구현은 `/v1/v1/...` 중복을 피하기 위해 base URL에 `/v1`를 포함하고 path 상수에서는 `/v1`를 제거한 구조다.
- backend 개별 서비스 직접 호출은 하지 않고, 허용 path만 Gateway client에서 검증한다.
- 현재 repo에는 CI workflow가 있지만 contract-check workflow와 `contract.lock.yml`은 아직 없다.
- Gateway login page 구분 기본값은 `explain`이다.

## 구현 근거
이 문서는 아래 구현 파일을 기준으로 정리했다.

| 파일 | 확인 내용 |
| --- | --- |
| `src/shared/config/security.ts` | Gateway base URL 끝에 `/v1`가 없으면 자동으로 붙인다. |
| `src/shared/config/auth.ts` | auth path 상수는 `/auth/**` 형태로 유지한다. |
| `src/shared/lib/api-client.ts` | 최종 URL 조립, 허용 path prefix 검증, `credentials: "include"`가 구현되어 있다. |
| `src/shared/api/auth.ts` | 세션 조회, refresh, logout이 cookie 기반 Gateway auth 흐름을 따른다. |

## 채택 공백
현재 구현과 contract 운영 관점 사이에 남아 있는 차이는 아래와 같다.

- `contract.lock.yml`이 없다.
- contract-check workflow가 없다.
- Gateway public contract를 소비하지만 artifact pin이나 upstream commit pin이 없다.
- path prefix allowlist는 구현돼 있지만, 이를 service-contract registry와 자동 대조하는 절차는 없다.
