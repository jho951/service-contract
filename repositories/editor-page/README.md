# Editor Page Contract

`Editor-page`는 브라우저에서 `gateway-service`만 직접 호출하는 Vite/React 프론트엔드다.
문서/블록 편집, 목록, 휴지통, 인증 bootstrap을 Gateway public `/v1/**` 계약에 맞춰 소비한다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/Editor-page |
| Branch | `master` |
| Contract Lock | 현재 구현에는 `contract.lock.yml` 없음 |

## 현재 구현 기준
- 기본 Gateway base URL은 `VITE_GATEWAY_BASE_URL` 또는 `VITE_API_BASE_URL`이고 기본값은 `http://localhost:8080`이다.
- API endpoint 상수에 `/v1/**`를 직접 포함한다.
- Axios 기본값과 fetch fallback 모두 `withCredentials` 또는 `credentials: "include"`를 사용한다.
- 브라우저는 backend 개별 서비스가 아니라 Gateway만 호출한다.
- 현재 v1에는 문서 복제 UI와 복제 API 소비가 없다. 문서 복제는 FE/BE 모두 v2 범위로 올린다.

## 운영 배포 자산

- EC2 image-only 배포 기준 산출물은 구현 repo의 `deploy/ec2/` 아래에 둔다.
- 기본 파일은 `docker-compose.yml`, `.env.production.example`, `README.md`이고, host Nginx reverse proxy example을 함께 둔다.

## 최근 구현 메모

- 홈/휴지통 목록 상단은 공용 `DocumentsPageHeader`로 통합됐다.
- 모바일에서는 로고를 메뉴 트리거로 쓰고, LNB는 전체 화면 overlay로 열린다.
- 홈/휴지통/LNB/블록 편집기는 context menu 중심 조작을 사용한다.
- 휴지통 상세 라우트 대신 목록 우클릭 기반 복구/완전 삭제 UX를 사용한다.

## URL 조립 규칙
Editor-page는 base URL과 endpoint를 아래처럼 조합한다.

| 항목 | 현재 구현 |
| --- | --- |
| Base URL | `http://localhost:8080` |
| Endpoint style | `/v1/...` |
| 최종 요청 예시 | `http://localhost:8080/v1/auth/me` |

예시:

```text
baseURL = http://localhost:8080
endpoint = /v1/auth/sso/start
final = http://localhost:8080/v1/auth/sso/start
```

이 구조에서는 base URL에 `/v1`를 추가하면 안 된다. 그렇게 바꾸면 `/v1/v1/...` 중복이 생긴다.

## 주요 소비 경로
| 목적 | 경로 |
| --- | --- |
| SSO 시작 | `GET /v1/auth/sso/start` |
| ticket 교환 | `POST /v1/auth/exchange` |
| 현재 세션 | `GET /v1/auth/me` |
| refresh | `POST /v1/auth/refresh` |
| logout | `POST /v1/auth/logout` |
| 문서 목록 | `GET /v1/documents` |
| 문서 상세 | `GET /v1/documents/{documentId}` |
| 문서 블록 | `GET /v1/documents/{documentId}/blocks` |
| 문서 저장 | `POST /v1/editor-operations/documents/{documentId}/save` |
| 이동 | `POST /v1/editor-operations/move` |
| 관리자 블록 | `/v1/admin/**` |

## 인증 흐름
현재 구현 기준 브라우저 인증 흐름은 아래 순서를 따른다.

```text
Editor-page
  -> GET /v1/auth/sso/start
  -> Gateway/Auth OAuth
  -> /auth/callback
  -> POST /v1/auth/exchange
  -> GET /v1/auth/me
  -> 필요 시 POST /v1/auth/refresh
```

세션 전달 방식:

- 브라우저는 access/refresh/session 값을 직접 저장하거나 Authorization header로 붙이지 않는다.
- Gateway/Auth가 내려준 cookie를 브라우저가 자동으로 보낸다.
- 프론트는 `withCredentials=true` 또는 `credentials: "include"`만 보장한다.

인증 상태 판단:

- `/v1/auth/me` 성공이면 로그인 상태로 본다.
- `/v1/auth/me`가 401이면 호출부에서 anonymous 또는 재인증 흐름으로 처리한다.
- refresh는 `POST /v1/auth/refresh`를 통해 cookie 기반으로 수행한다.

## 환경 변수
- `VITE_GATEWAY_BASE_URL`
- `VITE_API_BASE_URL`
- `VITE_DOCUMENTS_API_BASE_URL`
- `VITE_API_PROXY_TARGET`
- `VITE_START_FRONTEND_URL`
- `VITE_SITE_URL`

### 권장값
| 변수 | 권장값 | 설명 |
| --- | --- | --- |
| `VITE_GATEWAY_BASE_URL` | `http://localhost:8080` | `/v1`를 붙이지 않은 Gateway origin |
| `VITE_API_BASE_URL` | `http://localhost:8080` | legacy 호환용 base URL |
| `VITE_DOCUMENTS_API_BASE_URL` | `http://localhost:8080` | 문서 API도 현재는 Gateway 경유 |
| `VITE_API_PROXY_TARGET` | `http://localhost:8080` | Vite dev proxy 목적지 |
| `VITE_START_FRONTEND_URL` | `http://localhost:3000` | 시작 프론트/공용 로그인 시작점 |
| `VITE_SITE_URL` | `http://localhost:5173` | editor-page callback 및 절대 URL 기준 |

## 로컬 개발 전제
- Vite dev server 기본 포트는 `5173`이다.
- local Gateway 기본 포트는 `8080`이다.
- 개발 서버 문서에는 Vite proxy가 `/v1/**`와 legacy `/auth/**`를 backend로 전달한다고 적혀 있다.
- callback URL은 `VITE_SITE_URL` 기준 `/auth/callback`으로 만든다.

## 개발 품질 게이트
- 현재 구현 repo root에는 `eslint.config.js`와 `.eslintignore`가 있다.
- `package.json`에는 `npm run lint`와 `npm run typecheck` script가 있다.
- `npm run build`는 `npm run typecheck && vite build` 순서로 실행된다.
- 현재 구현 기준으로 `.husky/`, `prepare` script, `lint-staged` 설정은 없다.

## 자주 틀리는 설정
### 1. base URL에 `/v1`를 넣는 경우
잘못된 예:

```text
VITE_GATEWAY_BASE_URL=http://localhost:8080/v1
endpoint=/v1/auth/me
```

이 경우 최종 URL이 `/v1/v1/auth/me`가 된다.

### 2. backend 직접 호출로 바꾸는 경우
- 이 프론트의 현재 계약은 `auth-service`, `editor-service`, `user-service` 직접 호출이 아니다.
- 브라우저는 Gateway만 직접 호출해야 한다.

### 3. cookie 전송을 끄는 경우
- `withCredentials` 또는 fetch `credentials: "include"`가 빠지면 session 기반 인증이 깨진다.

## 구현 메모
- current 구현은 base URL에 `/v1`를 넣지 않고, endpoint 상수에 `/v1`를 넣는 방식이다.
- dev 문서에는 Vite proxy가 `/v1/**`와 legacy `/auth/**`를 backend로 전달한다고 적혀 있다.
- 현재 로컬 audit 시점의 작업 브랜치는 `codex/editor-auth-loop-fix`였지만, 기본 repo branch는 `master`로 관리한다.
- 현재 구현에는 `contract.lock.yml`과 contract-check workflow가 없다.

## v2 예정
- 문서 복제는 v1 범위가 아니다.
- FE는 LNB/GNB 등 문서 액션 UI에서 duplicate entry를 노출하고, backend v2 duplicate API를 소비하는 방식으로 올린다.
- 복제 결과는 새 문서 ID를 가진 독립 페이지여야 하며, 제목/icon/cover/body child node/preview 후보를 함께 복사하는 방향을 기본선으로 둔다.
- 즐겨찾기, recent, 공유 여부 같은 사용자별 관계 메타데이터는 원본에서 자동 승계하지 않는 방향을 기본선으로 둔다.
- FE 목록 정렬 UI는 최소 `수동`, `이름`, `생성일`, `수정일`을 지원한다.
- `수동`은 canonical order를 그대로 따르는 보기 모드다.
- `이름`, `생성일`, `수정일`은 사용자별 preference를 backend v2에서 읽고 저장하는 방식으로 올린다.
- 이름 정렬은 direction toggle UI를 둘 수 있고, backend는 `asc|desc` 방향을 함께 저장할 수 있어야 한다.

## 구현 근거
이 문서는 아래 구현 파일을 기준으로 정리했다.

| 파일 | 확인 내용 |
| --- | --- |
| `src/shared/api/client.ts` | Gateway base URL 기본값이 `http://localhost:8080`이고 axios `withCredentials=true`를 사용한다. |
| `src/shared/api/endpoints.ts` | API endpoint 상수가 `/v1/**` 형태로 선언되어 있다. |
| `src/features/auth/api/auth.ts` | SSO 시작, ticket 교환, 현재 세션 조회가 Gateway public auth route 기준으로 조립된다. |
| `.env.example` | 로컬 개발 시 Gateway origin 기본값이 `/v1` 없는 형태로 유지된다. |

## 채택 공백
현재 구현과 contract 운영 관점 사이에 남아 있는 차이는 아래와 같다.

- `contract.lock.yml`이 없다.
- contract drift를 검사하는 CI workflow가 없다.
- gateway public contract를 소비하지만, 이를 잠그는 machine-readable artifact pin이 없다.
- branch 실사용은 작업 브랜치 중심이지만, 계약 문서는 기본 브랜치 `master`를 source of truth로 적는다.
- commit 전 `lint` 또는 `typecheck`를 강제하는 Husky git hook이 없다.
- staged file 단위 lint gate를 위한 `lint-staged` 설정이 없다.
