# Troubleshooting

이 문서는 `service-contract` 레포와 연결된 서비스에서 자주 터지는 장애를 빠르게 분류하고 복구하기 위한 가이드다.

## 사용 원칙
- 먼저 증상을 보고 서비스 경계를 정한다.
- 그 다음 contract 문서와 서비스 구현의 불일치를 본다.
- 마지막에 `contract.lock.yml`, 브랜치, 환경변수, 캐시, OpenAPI 순으로 확인한다.

## 공통 점검
### 증상
- 서비스가 떠 있는데 요청이 계속 실패한다.
- 로컬과 스테이징의 동작이 다르다.
- 문서는 맞는데 구현이 다르다.

### 먼저 확인할 것
1. `git diff --check`
2. `./scripts/msa-stack.sh ps`
3. `contract.lock.yml`의 contract ref/SHA
4. 서비스 레포 브랜치
5. 최근 OpenAPI/contract 변경 이력

---

## 운영편 1: Gateway / Auth / Authz

### Gateway
#### 1. `ADMIN` 라우트가 항상 403으로 떨어짐
##### 증상
- `/v1/admin/**` 요청이 전부 거부된다.
- 사용자 인증은 되는데 관리자 경로만 실패한다.

##### 원인
- `Authz` 판정 호출 실패
- `X-User-Id`, `X-Original-Method`, `X-Original-Path` 누락
- IP guard가 차단
- `authz-service`가 200 대신 403을 반환

##### 확인
- `repositories/gateway-service/auth-proxy.md`
- `repositories/gateway-service/responsibility.md`
- `repositories/gateway-service/security.md`
- `repositories/authz-service/README.md`
- `curl -i http://localhost:8084/health`

##### 조치
1. Gateway가 재주입하는 내부 헤더를 확인한다.
2. `Authz`의 `/health`와 `/ready`를 확인한다.
3. `X-Original-Path`가 실제 관리자 경로와 맞는지 본다.
4. IP allowlist와 `GATEWAY_ADMIN_*` 설정을 확인한다.

#### 2. 인증은 되는데 업스트림이 안 보임
##### 증상
- Gateway가 200/401은 주는데 백엔드가 반응하지 않는다.
- 라우트는 맞지만 upstream 호출이 실패한다.

##### 원인
- `AUTH_SERVICE_URL`, `USER_SERVICE_URL`, `EDITOR_SERVICE_URL`, `AUTHZ_ADMIN_VERIFY_URL` 중 하나가 잘못됨
- shared network alias가 누락됨
- upstream 서비스가 다른 브랜치/포트로 떠 있음

##### 확인
- `repositories/gateway-service/execution.md`
- `repositories/gateway-service/env.md`
- `./scripts/msa-stack.sh up`

##### 조치
1. `./scripts/msa-stack.sh ps`로 컨테이너 이름과 포트를 본다.
2. current 기준 authz compose service key는 dev/prod 모두 `authz-service`인지 확인한다.
3. Gateway 환경변수가 실제 authz verify endpoint를 바라보는지 확인한다.
4. editor upstream은 current 구현 기준 `EDITOR_SERVICE_URL -> editor-service:8083`인지 확인한다.

#### 3. Gateway가 로그인 이후에도 세션을 못 찾음
##### 증상
- 브라우저에서 로그인 직후 다시 로그인하라고 뜬다.
- `sso_session` 또는 `ACCESS_TOKEN`이 무시된다.

##### 원인
- Cookie path/domain 불일치
- JWT 선검증 설정 불일치
- auth-service 세션 검증 실패

##### 확인
- `repositories/gateway-service/auth.md`
- `repositories/gateway-service/auth-flow.md`
- `repositories/auth-service/README.md`

##### 조치
1. 브라우저 Cookie가 실제로 전달되는지 확인한다.
2. `AUTH_JWT_VERIFY_ENABLED`와 JWKS를 확인한다.
3. auth-service의 세션 validate 엔드포인트를 직접 호출한다.

#### 4. CORS preflight가 204가 아니라 실패함
##### 증상
- 브라우저에서 `OPTIONS` 요청이 먼저 실패한다.
- 실제 API는 호출하기도 전에 막힌다.

##### 원인
- `Origin` 허용 목록이 비어 있거나 다름
- preflight 응답 헤더가 누락됨
- upstream이나 프록시가 이미 넣은 `Access-Control-Allow-*` 헤더와 Gateway 응답 헤더가 충돌함
- 프록시/로드밸런서가 `OPTIONS`를 가로챔

##### 확인
- `repositories/gateway-service/auth-proxy.md`
- `shared/security.md`

##### 조치
1. `Origin`과 CORS 설정을 비교한다.
2. `OPTIONS`가 Gateway까지 도달하는지 확인한다.
3. current Gateway 구현은 `beforeCommit`에서 기존 `Access-Control-Allow-*` 헤더를 지우고 다시 세팅하므로, 중복 헤더가 보이면 Gateway 앞단 프록시를 먼저 의심한다.
4. 응답의 `Access-Control-Allow-*` 헤더를 점검한다.

#### 5. INTERNAL 라우트가 거부됨
##### 증상
- 내부 호출만 401/403이 난다.
- 같은 요청을 외부에서 보내면 안 되고 내부에서만 되어야 하는 흐름이 막힌다.

##### 원인
- `X-Internal-Request-Secret` 누락
- 내부 JWT와 Gateway 재주입 컨텍스트 불일치
- 내부 네트워크가 아닌 경로로 호출

##### 확인
- `repositories/gateway-service/responsibility.md`
- `shared/security.md`

##### 조치
1. 내부 시크릿이 서비스 간 동일한지 확인한다.
2. 내부 호출 경로가 Gateway/mesh 기준인지 본다.

### Auth
#### 1. 로그인은 되는데 refresh가 실패함
##### 증상
- access token은 발급되지만 refresh 이후 세션이 끊긴다.
- refresh 직후 `/auth/me`가 401이 된다.

##### 원인
- refresh token 만료
- 세션 상태와 토큰 클레임 불일치
- 저장된 JWKS / 서명 키 불일치

##### 확인
- `repositories/auth-service/README.md`
- `repositories/auth-service/ops.md`
- `repositories/auth-service/v2.md`
- `/.well-known/jwks.json`

##### 조치
1. JWT issuer, audience, key id, clock skew를 확인한다.
2. 세션 저장소와 토큰 클레임이 같은 사용자 ID를 가리키는지 본다.
3. refresh 만료 정책을 다시 확인한다.

#### 2. SSO redirect 후 callback에서 깨짐
##### 증상
- provider redirect까지는 가는데 callback에서 실패한다.
- `ticket exchange`나 `state` 검증 실패가 난다.

##### 원인
- redirect URI가 provider 설정과 다름
- `state`/`nonce` 불일치
- callback 처리 시 origin/cookie가 사라짐

##### 확인
- `repositories/auth-service/ops.md`
- `repositories/auth-service/README.md`
- `repositories/auth-service/v2.md`

##### 조치
1. provider 등록 URI와 실제 callback URI를 비교한다.
2. 브라우저 쿠키 및 SameSite 정책을 본다.
3. ticket exchange 로그를 확인한다.

#### 3. `/.well-known/jwks.json`은 뜨는데 검증은 실패함
##### 증상
- 공개키 엔드포인트는 정상인데 클라이언트 검증 실패가 난다.

##### 원인
- 키 롤오버 후 캐시가 stale
- 사용하는 `kid`가 다름
- 알고리즘 설정이 맞지 않음

##### 확인
- `repositories/auth-service/ops.md`
- `shared/security.md`

##### 조치
1. JWKS의 `kid`와 토큰 헤더를 비교한다.
2. Gateway와 Auth가 같은 issuer/audience를 쓰는지 본다.

#### 4. 브라우저 로그인 루프가 계속됨
##### 증상
- 로그인 직후 다시 로그인 화면으로 돌아간다.
- 쿠키는 보이는데 인증이 유지되지 않는다.

##### 원인
- `SameSite` 또는 `Secure` 속성 불일치
- domain/path가 frontend와 다름
- refresh token은 있는데 access token이 만료됨

##### 확인
- `repositories/auth-service/README.md`
- `repositories/gateway-service/auth.md`
- `repositories/gateway-service/auth-flow.md`

##### 조치
1. 브라우저 개발자 도구에서 cookie 속성을 확인한다.
2. 개발/운영 환경의 domain과 path를 분리해서 본다.
3. refresh 후 `X-User-Id` 재주입이 유지되는지 본다.

#### 5. 내부 계정 생성/삭제가 실패함
##### 증상
- 관리자가 내부 계정 생성이나 삭제를 시도하면 실패한다.

##### 원인
- auth-service와 user-service의 계정 상태 기준이 다름
- 내부 계정 생성 API가 외부 라우트로 잘못 호출됨
- 운영 계정 정책이 잠김 상태

##### 확인
- `repositories/auth-service/ops.md`
- `repositories/auth-service/README.md`
- `repositories/user-service/ops.md`

##### 조치
1. 내부 계정 작업은 Gateway 또는 내부 네트워크만 사용하는지 확인한다.
2. 계정 상태와 정책을 다시 동기화한다.

### Authz
#### 1. 관리자 인가가 전부 403으로 떨어짐
##### 증상
- `POST /permissions/internal/admin/verify`가 거의 항상 403이다.
- Gateway의 관리자 경로도 같이 막힌다.

##### 원인
- seed 데이터 누락
- `X-User-Id` 기준 role/permission 매핑이 없거나 기대 권한과 다름
- 요청 메서드/경로 규칙과 seed policy가 다름

##### 확인
- `repositories/authz-service/README.md`
- `repositories/authz-service/ops.md`
- `repositories/authz-service/policy-model.md`
- `registry/service-ownership.md`

##### 조치
1. `permission-seed.sql` 기준으로 역할 seed를 확인한다.
2. `X-User-Id`와 실제 경로가 정책에 맞는지 본다.
3. Gateway가 전달하는 `X-Original-*` 헤더가 정확한지 확인한다.

#### 2. `GET /ready`가 DOWN인데 `POST /verify`는 동작함
##### 증상
- readiness만 실패하고 실제 판정 API는 일부 성공한다.

##### 원인
- Redis 장애
- dev compose의 `authz-mysql` healthcheck 실패
- DB 일부 마이그레이션 누락
- 캐시 초기화 실패

##### 확인
- `repositories/authz-service/ops.md`
- `repositories/redis-service/ops.md`

##### 조치
1. DB와 Redis 연결을 분리해서 본다.
2. dev 환경이면 `authz-mysql`이 먼저 healthy인지 확인한다.
3. 캐시 없이 DB fallback이 되는지 확인한다.
4. readiness가 `DOWN`인 이유를 로그에서 찾는다.

#### 3. 관리자 경로는 되는데 정책 조회가 어긋남
##### 증상
- `/v2/permissions/authorize`는 되는데 policy snapshot이 맞지 않는다.

##### 원인
- v1/v2 정책 모델이 서로 다른 상태
- 토큰 클레임에 `authzVersion`이 반영되지 않음
- policy engine 런타임 불일치

##### 확인
- `repositories/authz-service/v2.md`
- `repositories/authz-service/policy-engine.md`
- `repositories/authz-service/versioning.md`

##### 조치
1. v1과 v2가 같은 기준 데이터인지 확인한다.
2. `plugin-policy-engine` 버전을 본다.
3. 정책 변경 이벤트와 캐시 무효화 흐름을 확인한다.

#### 4. `400 PermissionBadRequestException`가 자주 뜸
##### 증상
- 입력이 조금만 달라도 400이 반환된다.

##### 원인
- 필수 헤더 누락
- 잘못된 `X-Original-Method` 또는 `X-Original-Path`
- JSON schema와 실제 요청 바디 불일치

##### 확인
- `repositories/authz-service/api.md`
- `artifacts/openapi/authz-service.upstream.v1.yaml`

##### 조치
1. 요청 헤더를 문서와 비교한다.
2. schema와 실제 request body를 맞춘다.

#### 5. 권한 변경 후 바로 반영되지 않음
##### 증상
- role grant/revoke 후에도 한동안 예전 권한이 보인다.
- 캐시를 비운 뒤에야 정상 반영된다.

##### 원인
- Redis 캐시 stale
- policy change 이벤트 미전파
- v1/v2 권한 상태가 서로 다름

##### 확인
- `repositories/authz-service/cache.md`
- `repositories/authz-service/versioning.md`
- `repositories/authz-service/audit.md`

##### 조치
1. 권한 변경 이벤트와 캐시 무효화 흐름을 확인한다.
2. `authzVersion`과 snapshot 버전을 비교한다.
3. 캐시 TTL을 줄여 재현 여부를 본다.

#### 6. `/permissions/internal/admin/verify` 경로가 안 맞음
##### 증상
- Gateway는 호출하는데 서비스는 404를 반환한다.
- 관리자 인가가 전부 fail-closed로 떨어진다.

##### 원인
- base path rewrite가 잘못됨
- 서비스와 Gateway의 내부 라우팅 경로가 불일치

##### 확인
- `repositories/gateway-service/auth-proxy.md`
- `artifacts/openapi/authz-service.upstream.v1.yaml`

##### 조치
1. Gateway가 전달하는 실제 path를 로그로 확인한다.
2. 서비스 OpenAPI path와 실제 route를 비교한다.

---

## 운영편 2: User / Redis / Audit Log

### User
#### 1. `/users/me`가 401/403으로 실패함
##### 증상
- 로그인은 된 것처럼 보이지만 me 조회가 안 된다.

##### 원인
- Gateway 재주입 `X-User-Id` 누락
- 내부 JWT와 외부 요청이 불일치
- 공개 API 대신 내부 API를 잘못 호출

##### 확인
- `repositories/user-service/README.md`
- `repositories/user-service/ops.md`
- `repositories/gateway-service/auth.md`

##### 조치
1. Gateway가 주입한 내부 컨텍스트를 확인한다.
2. user-service가 내부 JWT를 신뢰하도록 구성됐는지 본다.

#### 2. social link가 중복 생성됨
##### 증상
- 같은 계정에 소셜 링크가 여러 개 생긴다.

##### 원인
- `ensure-social` 또는 `find-or-create-and-link-social`이 멱등하지 않음
- provider alias 정규화가 다름

##### 확인
- `repositories/user-service/ops.md`
- `repositories/user-service/visibility.md`

##### 조치
1. `provider`, `providerUserId` 정규화 규칙을 재확인한다.
2. 멱등 키와 유니크 제약을 확인한다.

#### 3. 상태 변경 후 다운스트림 정책이 꼬임
##### 증상
- `ACTIVE`인데 downstream은 아직 비활성으로 본다.

##### 원인
- 상태 전파 지연
- 계약상 허용 상태와 구현 상태가 다름

##### 확인
- `repositories/user-service/ops.md`
- `repositories/user-service/v2-extension.md`

##### 조치
1. 상태 머신을 문서와 맞춘다.
2. 상태 변경 이벤트가 필요한지 확인한다.

#### 4. 프로필 공개 범위가 잘못 노출됨
##### 증상
- 공개되면 안 되는 필드가 보여진다.
- 반대로 보여져야 할 필드가 안 보인다.

##### 원인
- visibility policy와 실제 응답 필드가 다름
- Gateway/클라이언트가 캐시된 응답을 사용

##### 확인
- `repositories/user-service/visibility.md`
- `repositories/user-service/README.md`
- `registry/service-ownership.md`

##### 조치
1. 공개 필드와 내부 필드를 분리한다.
2. 캐시가 있다면 해당 응답을 무효화한다.

#### 5. 내부 사용자 생성/소셜 연동이 꼬임
##### 증상
- 내부 생성 후 social link가 연결되지 않는다.
- 중복 계정이 생긴다.

##### 원인
- `find-or-create-and-link-social` 멱등성 실패
- 이메일/소셜 기준 정규화가 다름

##### 확인
- `repositories/user-service/ops.md`
- `repositories/user-service/v2-extension.md`

##### 조치
1. 내부 사용자 생성과 소셜 연동을 분리해서 재현한다.
2. provider alias와 email normalization을 확인한다.

### Redis
#### 1. 캐시/세션이 전부 날아간 것처럼 보임
##### 증상
- 로그인 세션이 자주 풀린다.
- 관리자 권한 판정이 매번 느리다.

##### 원인
- TTL이 너무 짧음
- eviction 정책이 공격적임
- prefix contract가 깨짐

##### 확인
- `repositories/redis-service/ops.md`
- `repositories/redis-service/keys.md`
- `repositories/gateway-service/cache.md`

##### 조치
1. `gateway:session:`과 `gateway:admin-authz:` prefix를 확인한다.
2. TTL이 문서와 맞는지 본다.
3. key collision 여부를 확인한다.

#### 2. Redis 인증 실패 / 연결 실패
##### 증상
- 서비스가 Redis에 붙지 못한다.
- readiness가 DOWN이다.

##### 원인
- 비밀번호 불일치
- host/port 오타
- Redis가 `redis-server` / `redis`가 아닌 다른 이름으로 떠 있거나 shared network가 맞지 않음

##### 확인
- `repositories/redis-service/ops.md`
- `shared/env.md`

##### 조치
1. `redis-cli PING`으로 직접 확인한다.
2. 내부 호출 env는 `REDIS_HOST=redis`, Redis repo service key는 `redis-server`인지 확인한다.
3. Redis 예제 env의 `service-backbone-shared`와 실제 shared network 이름이 같은지 확인한다.

#### 3. 키 prefix가 섞임
##### 증상
- gateway 세션 키와 permission 키가 뒤섞인다.

##### 원인
- 새 prefix를 계약 문서보다 먼저 구현함
- 서비스별 key namespace가 충돌함

##### 확인
- `repositories/redis-service/keys.md`
- `repositories/redis-service/ops.md`

##### 조치
1. 새 prefix를 계약 레포에 먼저 추가한다.
2. 서비스 구현과 캐시 무효화 정책을 같이 맞춘다.

#### 4. eviction 때문에 특정 서비스만 자주 느려짐
##### 증상
- 로그인이 유지되는데 가끔 관리자 판정만 느려진다.
- 특정 키가 주기적으로 사라진다.

##### 원인
- `maxmemory`와 eviction policy가 트래픽 패턴과 맞지 않음
- `gateway:*` 또는 `permission:*` 키가 우선 축출됨

##### 확인
- `repositories/redis-service/ops.md`
- `repositories/redis-service/keys.md`

##### 조치
1. maxmemory와 eviction 정책을 확인한다.
2. key TTL과 cardinality를 다시 본다.
3. hot key가 몰리는지 확인한다.

#### 5. replication / failover 후 readiness만 흔들림
##### 증상
- Redis ping은 되는데 readiness가 DOWN/UP를 반복한다.

##### 원인
- replication lag
- failover 중 role 전환
- 준비 상태 체크가 너무 엄격함

##### 확인
- `repositories/redis-service/ops.md`
- `shared/env.md`

##### 조치
1. primary/replica 상태를 확인한다.
2. readiness 기준을 서비스 요구사항에 맞춘다.

### Audit Log
#### 1. 감사 이벤트가 안 쌓임
##### 증상
- 인증/인가/권한 변경 이벤트가 검색되지 않는다.

##### 원인
- 이벤트 발행 실패
- 서비스가 audit-log를 비동기로만 처리하다 유실
- 스키마 버전이 안 맞음

##### 확인
- `shared/audit.md`
- `shared/audit.md`

##### 조치
1. 발행 실패가 서비스 요청 실패로 이어져야 하는지 확인한다.
2. 최소한의 보안 이벤트는 재시도 경로를 둔다.

#### 2. 감사 저장이 서비스 전체 실패로 번짐
##### 증상
- audit-log 장애 후 다른 서비스가 전부 느려지거나 실패한다.

##### 원인
- 동기 저장을 과하게 강제함
- 서비스 계약에서 fail-open/fail-closed를 정하지 않음

##### 확인
- `shared/audit.md`
- 서비스별 `ops.md`

##### 조치
1. 고위험 이벤트만 동기 또는 준동기로 둔다.
2. 서비스별 장애 허용 정책을 다시 정의한다.

#### 3. 이벤트는 발행되는데 검색이 늦음
##### 증상
- 로그는 쌓였는데 바로 조회되지 않는다.
- 운영자가 방금 보낸 이벤트가 안 보인다.

##### 원인
- 수집 지연
- 인덱싱 lag
- 검색 범위와 보존 정책이 다름

##### 확인
- `shared/audit.md`
- `shared/audit.md`

##### 조치
1. 수집 지연과 저장 지연을 분리해서 본다.
2. 운영 검색 범위와 보존 정책을 맞춘다.

#### 4. 특정 서비스만 감사 이벤트가 누락됨
##### 증상
- Auth/Authz는 보이는데 User나 Editor 이벤트가 없다.

##### 원인
- 서비스별 audit producer 구현 누락
- 이벤트 타입이 문서와 다름

##### 확인
- `shared/audit.md`
- 서비스별 `ops.md`

##### 조치
1. 서비스별 발행 이벤트 목록을 비교한다.
2. 새 이벤트는 contract와 서비스 구현을 동시에 추가한다.

---

## 운영편 3: Editor / Block

### Editor / Block
#### 1. README와 실제 블록 연동 기준이 어긋나 보이면 먼저 오래된 branch 가정을 의심한다
##### 증상
- 문서에 적힌 브랜치와 실제 실행 브랜치가 다르다.
- `editor-service` 동기화가 안 된 것처럼 보인다.

##### 원인
- 과거 문서나 로컬 복사본이 `editor-service`를 `dev` 기준으로 설명하고 있을 수 있다.
- 현재 main 기준 SoT는 `editor-service`도 `main`이다.

##### 확인
- `registry/deployment-topology.md`
- `scripts/msa-stack.sh`

##### 조치
1. `editor-service`의 현재 기준 브랜치가 `main`인지 먼저 확인한다.
2. dev 기준 설명이 남아 있으면 stale 문서로 분류하고 갱신한다.

#### 2. editor v1/v2 스키마가 충돌함
##### 증상
- 문서/블록 저장은 되는데 응답 구조가 다르다.
- v1과 v2 문서가 서로 다른 기준으로 보인다.

##### 원인
- `schema-v1`과 `schema-v2`를 동시에 적용함
- 마이그레이션 문서 없이 구현만 바뀜

##### 확인
- `repositories/editor-service/README.md`
- `repositories/editor-service/db-migration.md`
- `repositories/editor-service/schema-v1.md`
- `repositories/editor-service/schema-v2.md`

##### 조치
1. v1과 v2를 동시에 활성화하지 않는다.
2. migration 순서를 먼저 문서화한다.

#### 3. Editor 권한은 되는데 실제 저장이 실패함
##### 증상
- `Authz` 판정은 통과하지만 편집/저장이 실패한다.

##### 원인
- 권한과 실제 실행 책임을 혼동함
- editor backend 데이터 정합성 실패

##### 확인
- `repositories/editor-service/authz.md`
- `repositories/editor-service/operations.md`
- `repositories/editor-service/ops.md`

##### 조치
1. `Authz`는 capability truth만 담당한다.
2. 실제 실행은 Editor/Block 도메인 계약을 다시 확인한다.

#### 4. 백업 복구 후 트리 구조가 깨짐
##### 증상
- 복구는 됐는데 문서 트리/블록 트리가 맞지 않는다.

##### 원인
- backup 시점과 version 정합성이 다름
- 부모/정렬 관계를 같이 복구하지 않음

##### 확인
- `repositories/editor-service/operations.md`
- `repositories/editor-service/ops.md`

##### 조치
1. 복구 전후에 문서 수, 부모 관계, 정렬 순서를 검증한다.
2. hard delete/soft delete 기준을 다시 확인한다.

#### 5. v1/v2 전환 후 읽기와 쓰기 계약이 어긋남
##### 증상
- 일부 노드는 보이는데 편집은 안 된다.
- v1과 v2 스키마가 같이 섞여 보인다.

##### 원인
- migration step이 반만 진행됨
- v1/v2 OpenAPI와 구현 버전이 분리되지 않음

##### 확인
- `repositories/editor-service/schema-v1.md`
- `repositories/editor-service/schema-v2.md`
- `repositories/editor-service/db-migration.md`

##### 조치
1. v1-only와 v2-only 구간을 분명히 나눈다.
2. migration 전/후 snapshot을 비교한다.

#### 6. Block read/write만 부분적으로 실패함
##### 증상
- 문서는 열리는데 블록 수정만 안 되거나 반대 상황이 생긴다.

##### 원인
- 오래된 editor-service branch 기준 문서와 현재 main 구현이 불일치
- block API와 editor API가 서로 다른 contract를 참조

##### 확인
- `registry/deployment-topology.md`
- `repositories/editor-service/README.md`
- `repositories/editor-service/api.md`

##### 조치
1. Block 서버 브랜치와 실행 스크립트를 현재 main 기준으로 맞춘다.
2. editor가 참조하는 block contract 버전을 확인한다.

#### 7. `segment`에 block type을 넣으면 editor validation이 400으로 실패함
##### 증상
- block 저장 요청은 가는데 `400`이나 validation 실패로 떨어진다.
- `segment.type`, `segment.blockType` 같은 필드를 넣은 payload만 실패한다.
- 같은 요청에서 `text`, `marks`만 남기면 통과한다.

##### 원인
- current editor validator는 `segment`에 `text`, `marks`만 허용한다.
- rich-text subtype은 `segment`가 아니라 optional `content.blockType`으로만 받는다.
- top-level `Block.type`은 계속 `TEXT`이고, `content.blockType` 허용값은 `paragraph`, `heading1`, `heading2`, `heading3`다.

##### 확인
- `repositories/editor-service/schema-v1.md`
- `repositories/editor-service/rules-v1.md`
- `repositories/editor-service/api.md`

##### 조치
1. block subtype이 필요하면 `content.blockType`으로 보낸다.
2. `segment`에는 `text`, `marks`만 남긴다.
3. `content.blockType`을 생략했다면 paragraph 기본형으로 해석되는지 함께 확인한다.

#### 8. 여러 블록 선택 기준으로 요청을 보냈는데 editor API shape가 맞지 않음
##### 증상
- 프론트가 여러 선택 블록을 한 번에 move, delete, edit하려고 `selectedBlockIds`, `blockIds`, selection range 같은 필드를 기대한다.
- 한 번의 move 요청으로 여러 블록을 옮기려는데 API가 단일 `blockRef` 또는 단일 `resourceId`만 받는다.
- batch save가 있으니 multi-select도 당연히 지원한다고 오해한다.

##### 원인
- current v1 editor save batch는 여러 단일 블록 operation의 순차 적용 모델이다.
- save operation은 단일 `blockRef`, move operation은 단일 `resourceId` 기준으로 설계돼 있다.
- 여러 블록 delete나 subtype 일괄 변경은 여러 단건 operation으로 풀 수 있지만, 여러 블록의 상대 순서를 보존한 group move semantics는 v1에 없다.

##### 확인
- `repositories/editor-service/schema-v1.md`
- `repositories/editor-service/rules-v1.md`
- `repositories/editor-service/api.md`
- `repositories/editor-service/operations.md`

##### 조치
1. 현재 v1 범위에서는 multi-select 자체를 서버 계약으로 가정하지 않는다.
2. 여러 블록 delete나 subtype 일괄 변경은 클라이언트가 여러 `BLOCK_DELETE` 또는 `BLOCK_REPLACE_CONTENT` operation으로 batch를 조립한다.
3. 여러 선택 블록의 상대 순서를 유지한 bulk move가 필요하면 별도 request, validation, result 계약을 추가하는 방향으로 설계한다.

#### 9. block move 요청이 `400`으로 실패하면 먼저 `save batch의 BLOCK_MOVE`와 explicit move endpoint를 구분한다
##### 증상
- block move를 구현했는데 어떤 요청은 통과하고 어떤 요청은 같은 의미처럼 보여도 `400`으로 실패한다.
- 프론트가 `blockRef`, `parentRef`, `afterRef`, `beforeRef` shape를 `POST /v1/editor-operations/move`에도 그대로 보낸다.
- 반대로 explicit move endpoint에 필요한 `resourceType`, `resourceId`, `targetParentId`, `afterId`, `beforeId`, `version` 없이 호출한다.

##### 원인
- current 구현에는 block move 경로가 2개 있다.
- save batch 안의 `BLOCK_MOVE`는 `blockRef`, `parentRef`, `afterRef`, `beforeRef`를 쓰고, 같은 batch 안의 temp ref도 해석할 수 있다.
- explicit move endpoint `POST /v1/editor-operations/move`는 `resourceType`, `resourceId`, `targetParentId`, `afterId`, `beforeId`를 쓰며 temp ref를 받지 않는다.

##### 확인
- `repositories/editor-service/api.md`
- `repositories/editor-service/rules-v1.md`
- `repositories/editor-service/operations.md`
- `repositories/editor-page/README.md`

##### 조치
1. editor-page 저장 queue 안의 이동이면 `POST /v1/editor-operations/documents/{documentId}/save` + `type=BLOCK_MOVE`를 사용한다.
2. drag-and-drop 확정 이동처럼 explicit move contract를 쓸 때는 `POST /v1/editor-operations/move`와 `resourceType=BLOCK` shape를 사용한다.
3. 두 endpoint의 request 필드를 섞어 쓰지 않는다.

#### 10. explicit block move는 `version`이 없으면 유효성 검사에서 바로 막힌다
##### 증상
- `POST /v1/editor-operations/move`가 `400`으로 떨어지고 서버 비즈니스 로직까지 들어가지 않는다.
- 문서 move는 되는데 block move만 실패한다.

##### 원인
- current explicit move DTO는 `resourceType=BLOCK`이면 `version`을 필수로 요구한다.
- 기존 서버 block 이동은 낙관적 락 기준이므로, 최신 block version 없이 move를 허용하지 않는다.

##### 확인
- `repositories/editor-service/api.md`
- `repositories/editor-service/rules-v1.md`

##### 조치
1. explicit block move에는 항상 현재 block `version`을 함께 보낸다.
2. 문서 move와 block move의 요청 shape를 동일하게 취급하지 않는다.
3. 같은 batch 안의 temp block 이동처럼 `version` 없는 move가 필요한 경우는 explicit move endpoint가 아니라 save batch `BLOCK_MOVE` 경로를 사용한다.

#### 11. block move가 같은 자리 drop이면 실패가 아니라 no-op 성공일 수 있다
##### 증상
- 사용자는 블록을 움직였다고 생각하지만 응답 후 version과 documentVersion이 그대로다.
- 저장이 안 된 것처럼 보이지만 에러는 없다.

##### 원인
- current 구현은 같은 위치로 계산된 block move를 no-op 성공으로 처리한다.
- save batch에서는 `BLOCK_MOVE` status가 `NO_OP`가 될 수 있고, explicit move에서도 증가하지 않은 block/document version을 그대로 응답할 수 있다.

##### 확인
- `repositories/editor-service/operations.md`
- `repositories/editor-service/rules-v1.md`

##### 조치
1. no-op move를 실패로 처리하지 않는다.
2. 프론트는 응답의 `version`, `documentVersion`, `sortKey`, 또는 save batch의 `status=NO_OP`를 기준으로 로컬 상태를 동기화한다.
3. drag 중간 hover 변화가 아니라 최종 drop 위치만 move 요청으로 보내도록 유지한다.

#### 12. block move에서 anchor 조합이나 target parent가 조금만 어긋나도 `INVALID_REQUEST`가 난다
##### 증상
- block move가 `400 INVALID_REQUEST`로 실패한다.
- `afterId`, `beforeId`, `afterRef`, `beforeRef`를 넣었는데 어떤 조합에서는 바로 거절된다.
- 다른 문서의 블록을 parent나 anchor로 참조했을 때 실패한다.

##### 원인
- current 구현은 self-anchor, same-anchor, reversed anchor, target parent와 맞지 않는 anchor 조합을 잘못된 요청으로 거절한다.
- target parent는 같은 document의 active block이어야 하고, 자기 자신이나 자기 하위 subtree 아래로 이동하는 cycle도 허용하지 않는다.
- block depth 제한을 넘는 이동도 거절된다.

##### 확인
- `repositories/editor-service/operations.md`
- `repositories/editor-service/rules-v1.md`
- `repositories/editor-service/api.md`

##### 조치
1. `after*`와 `before*`는 같은 target sibling 집합을 가리키도록 보낸다.
2. 다른 document 소속 block을 `targetParentId`, `afterId`, `beforeId`, `parentRef`, `afterRef`, `beforeRef`로 보내지 않는다.
3. 자기 자신, 자기 자식 subtree 아래로 이동하는 cycle 요청은 만들지 않는다.
4. save batch에서는 temp anchor를 쓸 수 있지만, 아직 생성되지 않은 temp anchor를 먼저 참조하면 실패하므로 request 순서를 맞춘다.

### Authz/Permission bridge
#### 1. Gateway는 `Authz`라고 부르는데 로그는 `authz-service`로 남음
##### 증상
- 문서와 로그 용어가 다르다.

##### 원인
- 외부 표시는 `Authz`, 내부 HTTP 호스트명은 `authz-service`를 사용함.

##### 확인
- `repositories/gateway-service/env.md`
- `artifacts/openapi/authz-service.upstream.v1.yaml`

##### 조치
1. 문서상 책임명은 `Authz`로 본다.
2. 네트워크 호스트명과 컨테이너명은 실제 실행 기준을 따른다.

#### 2. 서비스명과 repo명이 섞여서 온보딩이 꼬임
##### 증상
- 문서마다 `Authz`, `authz-service`, `Permission-server`가 섞여 보인다.

##### 원인
- 책임명, HTTP 호스트명, GitHub repo 이름을 같은 레벨로 읽음

##### 확인
- `README.md`
- `repositories/authz-service/README.md`
- `scripts/msa-stack.sh`

##### 조치
1. 책임명은 `Authz`로 본다.
2. URL과 컨테이너명은 실제 실행 식별자로 본다.
3. repo URL은 원격에 맞춘다.

## 빠른 확인 명령
```bash
./scripts/msa-stack.sh init
./scripts/msa-stack.sh ps
./scripts/msa-stack.sh up
./scripts/msa-stack.sh down
```

```bash
git diff --check
```

## 관련 문서
- [Lifecycle](lifecycle.md)
- [Automation](automation.md)
- [Contract Lock Template](../templates/contract-lock-template.yml)
- [Agent Task Template](../templates/agent-task-template.md)

---

## 최근 정합성 수정 기준

### Compose / Local 실행 드리프트

#### 0. `docker/*/compose.yml`의 기본 `env_file` 상대경로는 직접 `docker compose` 실행 시 깨질 수 있다
##### 증상
- `docker compose -f docker/compose.yml -f docker/dev/compose.yml up` 같은 직접 실행에서 `.env.dev` 또는 `.env.prod`를 못 찾는다.
- `gateway-service`, `auth-service`는 즉시 실패하거나 필수 값이 비어 있는 상태로 뜬다.
- `authz-service`는 컨테이너는 올라오지만 `.env` 값이 빠진 채로 실행된다.

##### 원인
- 아래 compose 파일들의 기본 `env_file`이 `../.env.dev`, `../.env.prod`처럼 잡혀 있다.
- Compose는 경로를 compose 파일 기준으로 해석하므로 실제로는 `docker/.env.dev`, `docker/.env.prod`를 가리킨다.
- 실제 파일은 서비스 루트의 `.env.dev`, `.env.prod`다.

##### 확인
- `gateway-service/docker/dev/compose.yml`
- `gateway-service/docker/prod/compose.yml`
- `auth-service/docker/dev/compose.yml`
- `auth-service/docker/prod/compose.yml`
- `authz-service/docker/dev/compose.yml`
- `authz-service/docker/prod/compose.yml`
- `gateway-service/scripts/run.docker.sh`
- `auth-service/scripts/run.docker.sh`

##### 조치
1. 직접 compose를 실행할 때는 `GATEWAY_ENV_FILE`, `AUTH_ENV_FILE` 같은 override를 명시한다.
2. compose 기본값은 `../../.env.dev`, `../../.env.prod`로 맞추는 편이 안전하다.
3. 현재 스크립트 실행은 `*_ENV_FILE`을 정확한 절대/상대 경로로 넘기므로 대체로 정상이다.
4. `authz-service`는 `required: false`라서 즉시 죽지 않을 뿐, 값이 빠진 채 떠 있을 수 있다는 점을 별도로 본다.

#### 1. Gateway local과 auth-service local의 포트 기준이 서로 다르면 host bootRun이 바로 어긋난다
##### 증상
- 과거 제보에서는 Gateway local은 auth-service를 `localhost:8081`로 기대하는데 실제 auth-service local은 `8082`에서 뜬다고 되어 있었다.
- 현재 main 기준 값이 바뀌었는지 확인하지 않으면 오래된 로컬 복사본을 현재 장애로 오판할 수 있다.

##### 원인
- `gateway-service/.env.local`은 `AUTH_SERVICE_URL=http://localhost:8081`를 사용한다.
- 현재 main 기준 `auth-service/.env.local`은 `SERVER_PORT=8081`이다.
- `user-service/app/src/main/resources/application-dev.yml`의 기본 포트도 `8082`다.
- 참고로 Gateway local에는 예전처럼 별도 `AUTH_VALIDATE_URL`이 있지 않고, validate 호출도 `AUTH_SERVICE_URL` 기준으로 파생된다.

##### 확인
- `repositories/gateway-service/env.md`
- `repositories/auth-service/README.md`
- `repositories/user-service/README.md`

##### 조치
1. 현재 main 기준 canonical local 포트는 auth-service `8081`, user-service `8082`다.
2. 누군가 auth-service local을 `8082`로 보고 있으면 stale `.env.local` 또는 다른 브랜치를 먼저 의심한다.
3. host bootRun 점검 시에는 Gateway `AUTH_SERVICE_URL`과 auth-service `SERVER_PORT`가 둘 다 `8081`인지부터 본다.

#### 2. `auth-service/.env.local`의 `USER_SERVICE_BASE_URL=8083` 문제 제보는 현재 main 기준으로는 재현되지 않는다
##### 증상
- 과거 제보에는 auth-service local이 user-service를 `8083`으로 바라본다고 적혀 있었다.

##### 원인
- 현재 main 기준 `auth-service/.env.local`의 `USER_SERVICE_BASE_URL`은 이미 `http://localhost:8082`로 정리돼 있다.
- 따라서 이 항목은 “현재 장애”가 아니라 “오래된 로컬 복사본 또는 다른 브랜치 drift” 가능성으로 봐야 한다.

##### 확인
- `auth-service/.env.local`
- `user-service/app/src/main/resources/application-dev.yml`

##### 조치
1. 현재 main 기준 문서에는 이 항목을 활성 장애가 아니라 stale config 경고로 기록한다.
2. 누군가 local에서 `8083`을 보고 있다면 오래된 `.env.local` 또는 다른 브랜치를 먼저 의심한다.

#### 3. auth-service local과 user-service local의 내부 JWT shared secret이 다르면 내부 user lookup이 깨질 수 있다
##### 증상
- auth-service에서 user-service 내부 호출이 401/403으로 실패한다.
- local에서는 로그인 또는 내부 계정 조회가 불안정하다.

##### 원인
- `auth-service/.env.local`의 `USER_SERVICE_JWT_SECRET`과 `user-service/.env.local`의 `USER_SERVICE_INTERNAL_JWT_SECRET`가 다르다.
- auth-service는 이 secret으로 내부 JWT를 서명하고, user-service는 다른 secret으로 검증한다.

##### 확인
- `auth-service/.env.local`
- `user-service/.env.local`
- `shared/env.md`

##### 조치
1. 두 값을 반드시 같은 shared secret으로 맞춘다.
2. local, Docker, 배포 예시 파일이 서로 다른 값을 갖고 있지 않은지 같이 확인한다.

#### 4. auth-service MySQL init 스크립트는 prod에서 env와 명확히 어긋나고, dev에서도 env override를 따르지 않는다
##### 증상
- prod에서 auth-service가 기대하는 DB/user와 실제 init.sql이 만든 DB/user가 다를 수 있다.
- dev에서 `.env.dev`를 바꿔도 MySQL 초기화는 계속 하드코딩 값으로 진행된다.

##### 원인
- `auth-service/.env.prod`와 런타임 예시는 `auth_service_db`, `auth_user`, `auth_password`를 기대한다.
- 그런데 `auth-service/docker/prod/services/mysql/init.sql`은 `prod_db`, `readonly_user`, `strongpassword`를 생성한다.
- `auth-service/docker/dev/services/mysql/init.sql`도 `auth_service_db`, `auth_user`, `auth_password`를 하드코딩해서 env 변경을 따라가지 않는다.

##### 확인
- `auth-service/.env.example`
- `auth-service/docker/dev/services/mysql/init.sql`
- `auth-service/docker/prod/services/mysql/init.sql`

##### 조치
1. 최소한 prod init.sql은 현재 env 계약과 같은 DB/user/password로 즉시 맞춘다.
2. dev도 env override를 허용할지, init.sql 하드코딩을 계약으로 굳힐지 하나로 정한다.
3. 더 나은 방향은 init.sql 의존을 줄이고 MySQL image env와 마이그레이션 체계로 일원화하는 것이다.

#### 5. auth-service local SSO callback은 Gateway ingress 기준 `127.0.0.1:8080`과 일치해야 한다
##### 증상
- local SSO를 볼 때 어떤 문서는 Gateway callback을 말하고, 어떤 env는 auth-service 직결 callback을 말해 혼란이 생긴다.
- `redirect_uri` mismatch를 디버깅할 때 실제 활성 경로와 env 값이 달라 보인다.

##### 원인
- 현재 auth-service dev Spring OAuth2 설정은 `redirect-uri: "{baseUrl}/v1/login/oauth2/code/{registrationId}"`를 사용한다.
- 프런트도 `GET /v1/auth/sso/start`처럼 Gateway 공개 경로를 기준으로 로그인 시작을 만든다.
- 현재 main 기준 `auth-service/.env.local`, `.env.dev`, `.env.example`의 `SSO_GITHUB_CALLBACK_URI`는 `http://127.0.0.1:8080/v1/login/oauth2/code/github`다.
- 추가로 현재 코드 기준 `SSO_GITHUB_CALLBACK_URI`는 `sso.github.callback-uri`로 로드되지만, active Spring OAuth2 login redirect 계산에는 직접 쓰이지 않는다.

##### 확인
- `auth-service/.env.local`
- `auth-service/app/src/main/resources/dev/application-dev_auth.yml`
- `auth-service/app/src/main/resources/dev/application-dev_sso.yml`
- `repositories/auth-service/README.md`
- `repositories/gateway-service/auth-flow.md`

##### 조치
1. current MSA ingress 계약은 Gateway-first이므로 local 문서와 예시는 `http://127.0.0.1:8080/v1/login/oauth2/code/github`를 canonical 값으로 둔다.
2. GitHub OAuth App callback URL도 브라우저 테스트 호스트와 동일한 `127.0.0.1:8080`으로 맞춘다.
3. 누군가 `localhost:8082/login/oauth2/code/github`를 보고 있으면 오래된 env 파일 또는 stale branch 문맥으로 분류한다.

### 1. Gateway 로컬 JWT 검증과 auth-service 서명키가 다르면 보호 경로가 불안정해진다
#### 증상
- `Bearer` 토큰이 있는데도 Gateway가 보호 경로를 401로 거부한다.
- 같은 토큰이 auth-service에서는 유효한데 Gateway에서만 실패한다.

#### 원인
- `AUTH_JWT_VERIFY_ENABLED=true` 상태에서 Gateway `AUTH_JWT_SHARED_SECRET`와 auth-service `AUTH_JWT_SECRET`가 다르다.

#### 확인
- `repositories/gateway-service/auth.md`
- `repositories/auth-service/ops.md`

#### 조치
1. Gateway의 `AUTH_JWT_SHARED_SECRET`를 auth-service `AUTH_JWT_SECRET`와 동일하게 맞춘다.
2. HS256 검증을 유지할지, auth-service validate 호출만 사용할지 운영 모드를 고정한다.

### 2. GitHub OAuth callback은 Gateway public callback으로 고정해야 한다
#### 증상
- GitHub OAuth authorize까지는 가지만 callback 단계에서 `redirect_uri is not associated` 오류가 난다.

#### 원인
- provider 등록값이 upstream `/login/oauth2/code/github`를 바라보거나, host는 맞아도 public `/v1/login/oauth2/code/github`를 쓰지 않는다.

#### 확인
- `repositories/auth-service/api.md`
- `artifacts/openapi/auth-service.upstream.v1.yaml`
- `artifacts/openapi/gateway-service.public.v1.yaml`

#### 조치
1. GitHub OAuth App callback은 항상 Gateway public callback으로 등록한다.
2. 기준 경로는 `https://<gateway-domain>/v1/login/oauth2/code/github`다.
3. auth-service upstream callback `/login/oauth2/code/github`는 외부 provider에 직접 등록하지 않는다.

### 3. auth-service 예시 파일과 로컬 런타임 값도 실제 Docker topology와 같아야 한다
#### 증상
- `.env.example`만 복사해서 띄우면 Redis DNS를 못 찾는다.
- IntelliJ local bootRun에서 user lookup이 다른 서비스 포트로 간다.

#### 원인
- Redis host가 `redis`가 아닌 다른 이름으로 남아 있다.
- local `USER_SERVICE_BASE_URL`이 실제 user-service 포트 `8082`와 다르다.

#### 확인
- `repositories/auth-service/README.md`
- `repositories/user-service/README.md`

#### 조치
1. auth-service 예시 Redis host는 `redis`로 유지한다.
2. local `USER_SERVICE_BASE_URL`은 `http://localhost:8082` 기준으로 맞춘다.

### 4. Monitoring은 dev와 prod target 파일을 분리해야 한다
#### 증상
- local Docker에서는 Prometheus가 target을 못 긁거나 전부 `unknown`으로 남는다.
- 운영 대시보드 label과 local label이 섞여 서비스가 분산된다.

#### 원인
- EC2 내부 DNS target을 local Docker dev compose에 그대로 사용한다.
- `permission-service`, `gateway` 같은 옛 runtime name이 target/label에 남아 있다.

#### 확인
- `repositories/monitoring-service/targets.md`
- `repositories/monitoring-service/ops.md`

#### 조치
1. dev는 Docker service name(`auth-service`, `user-service`, `editor-service`, `authz-service`, `gateway-service`)을 사용한다.
2. prod는 EC2 internal hostname target을 유지한다.
3. gateway/authz service label은 `gateway-service`, `authz-service`로 통일한다.

### 5. Gateway platform-security release train을 같이 맞춘다
#### 증상
- 빌드는 되거나 안 되거나 환경마다 달라지고, runtime linkage 문제가 날 수 있다.

#### 원인
- `platform-runtime-bom`, `platform-governance-bom`, `platform-security-bom`, `platform-security-hybrid-web-adapter` release train이 서로 다르다.
- Gateway는 hybrid add-on 기반이라 `platform-security` family와 Spring Boot/Spring Cloud 조합이 어긋나면 reactive filter/runtime 쪽에서 바로 드러난다.

#### 확인
- `repositories/gateway-service/README.md`
- `repositories/gateway-service/security.md`

#### 조치
1. Gateway 기준 platform 조합은 `platform-runtime-bom 3.0.1`, `platform-governance-bom 3.0.1`, `platform-security-bom 3.0.1`, `platform-security-hybrid-web-adapter 3.0.1`로 같이 맞춘다.
2. `GatewayApplication`은 `PlatformSecurityHybridWebAdapterAutoConfiguration`만 exclude 하고, platform starter 전체를 꺼서는 안 된다.
3. Spring Boot / Spring Cloud 정합성도 함께 본다. 현재 gateway-service root plugin baseline은 `Spring Boot 3.4.10`, `Spring Cloud 2024.0.1`이다.

### 6. authz-service dev compose에 Redis가 내장돼 있으면 branch drift를 의심한다
#### 증상
- authz dev stack과 redis-service dev stack을 같이 올릴 때 `6379` 충돌 또는 `redis` alias 충돌이 난다.

#### 원인
- 최신 main이 아니라 과거 branch에서 authz-service dev compose가 Redis를 함께 띄우는 경우가 있다.

#### 확인
- `repositories/authz-service/ops.md`
- `repositories/redis-service/README.md`

#### 조치
1. 최신 기준 authz-service dev compose에는 Redis가 없어야 한다.
2. 공용 Redis host는 `redis-service`의 `redis` 하나만 사용한다.

### 7. `GET /v1/auth/sso/start`는 파라미터 없이 호출하면 `400 / 9015 INVALID_REQUEST`로 실패한다
#### 증상
- `GET /v1/auth/sso/start` 호출 직후 `잘못된 요청입니다.`, `code=9015`가 반환된다.
- Gateway까지는 붙지만 provider redirect로 넘어가지 못한다.

#### 원인
- 현재 auth-service 구현은 `page`와 `redirect_uri`가 둘 다 비어 있으면 SSO 시작 요청을 거부한다.
- 허용 `page` 값도 `explain`, `editor`, `admin`처럼 제한돼 있다.
- 일부 contract/README 예시는 여전히 파라미터 없는 `GET /v1/auth/sso/start`를 보여 주므로 구현과 문서가 어긋날 수 있다.

#### 확인
- `repositories/auth-service/README.md`
- `repositories/editor-page/README.md`
- `repositories/explain-page/README.md`
- `repositories/gateway-service/auth-flow.md`

#### 조치
1. editor는 `GET /v1/auth/sso/start?page=editor`를 쓴다.
2. explain은 `GET /v1/auth/sso/start?page=explain`를 쓴다.
3. admin은 `GET /v1/auth/sso/start?page=admin`를 쓴다.
4. `redirect_uri`를 직접 넘길 때는 auth-service 허용 목록과 완전히 같은 값만 사용한다.
5. contract 예시가 파라미터 없는 호출을 보여 주면 stale example로 보고 수정한다.

### 8. GitHub OAuth는 `localhost`와 `127.0.0.1`을 같은 redirect URI로 보지 않는다
#### 증상
- GitHub authorize 이후 `Be careful! The redirect_uri is not associated with this application.`가 나온다.
- 로그인은 시작되는데 callback 단계에서 provider가 막는다.
- 같은 로컬 머신인데도 어떤 브라우저 탭은 되고 어떤 탭은 안 된다.

#### 원인
- GitHub OAuth App callback URL은 호스트까지 완전히 일치해야 한다.
- `http://localhost:8080/v1/login/oauth2/code/github`와 `http://127.0.0.1:8080/v1/login/oauth2/code/github`는 서로 다른 URI다.
- 브라우저 접속 host와 GitHub App 설정 host를 섞으면 provider mismatch와 cookie scope 혼선이 같이 난다.

#### 확인
- `repositories/auth-service/README.md`
- `repositories/gateway-service/auth-flow.md`
- `shared/env.md`

#### 조치
1. 로컬 기준 host를 하나만 고른다.
2. `127.0.0.1`로 통일할 경우 브라우저, 프런트 env, auth-service 허용 redirect, GitHub OAuth App callback URL을 모두 `127.0.0.1`로 맞춘다.
3. `localhost`로 통일할 경우도 같은 원칙으로 전부 `localhost`만 사용한다.
4. `localhost:3000`, `127.0.0.1:3000`, `localhost:8080`, `127.0.0.1:8080`를 섞어 쓰지 않는다.

### 9. Explain-page와 Editor-page는 각자 자기 `page`와 callback으로 로그인 시작을 고정해야 한다
#### 증상
- Explain-page에서 로그인했는데 editor 쪽으로 보내진다.
- callback 이후 원래 프런트가 아니라 다른 프런트로 복귀한다.
- `/v1/auth/me?page=explain`처럼 auth 확인 쿼리를 바꿔도 로그인 목적지가 바뀌지 않는다.

#### 원인
- 로그인 목적지는 `/v1/auth/sso/start` 시점의 `page`와 `redirect_uri`로 결정된다.
- `/v1/auth/me`의 `page=...` 쿼리는 세션 확인용 보조 정보일 뿐, 이미 만들어진 SSO 목적지를 바꾸지 않는다.
- 프런트가 editor용 `page=editor` 또는 editor callback URL을 재사용하면 explain 로그인도 editor로 귀결된다.

#### 확인
- `repositories/editor-page/README.md`
- `repositories/explain-page/README.md`
- `repositories/gateway-service/auth-flow.md`

#### 조치
1. Editor-page 로그인 시작은 `page=editor`와 editor callback URL을 사용한다.
2. Explain-page 로그인 시작은 `page=explain`와 explain callback URL을 사용한다.
3. 두 프런트 모두 local에서 host 통일 원칙을 따라 `127.0.0.1` 또는 `localhost` 중 하나만 쓴다.
4. callback 이후 잘못된 프런트로 돌아간다면 `/v1/auth/sso/start` 호출 시점의 `page`, `redirect_uri`, `next`를 먼저 본다.

### 10. 브라우저 `OPTIONS /v1/auth/me`가 `403`이면 먼저 Gateway CORS preflight를 본다
#### 증상
- 브라우저 DevTools에서 `OPTIONS http://127.0.0.1:8080/v1/auth/me?page=explain`가 `403 Forbidden`이다.
- 실제 `GET /v1/auth/me`는 날아가지도 못한다.
- 응답에 `Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials`가 없거나 부족하다.

#### 원인
- Gateway가 브라우저 preflight를 프레임워크 레벨에서 먼저 허용하지 못한다.
- 허용 origin 목록과 실제 프런트 origin이 다르다.
- `credentials: include`를 쓰는데 CORS 응답 헤더가 그것과 맞지 않는다.
- 앞단 프록시가 Gateway가 정규화한 `Access-Control-Allow-*` 헤더를 다시 덧붙인다.

#### 확인
- `repositories/gateway-service/auth.md`
- `repositories/gateway-service/auth-flow.md`
- `shared/security.md`

#### 조치
1. 브라우저 origin과 Gateway CORS 허용 origin을 정확히 맞춘다.
2. `OPTIONS` 응답에 `Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials`, `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers`가 모두 있는지 본다.
3. 로컬 기준 origin이 `http://127.0.0.1:3000`이면 Gateway도 그 값을 명시적으로 허용해야 한다.
4. current Gateway 구현은 `beforeCommit`에서 CORS 헤더를 정규화하므로, 동일 헤더가 중복되면 Nginx/프록시 레이어를 먼저 점검한다.

### 11. 쿠키가 있는데도 `GET /v1/auth/me`가 `401 authentication required`면 Gateway/Auth의 세션 판정 순서를 같이 본다
#### 증상
- 브라우저 요청 헤더에 `sso_session`, `ACCESS_TOKEN`, `refresh_token`, `JSESSIONID`가 있는데도 `GET /v1/auth/me`가 `401`이다.
- Redis에는 `auth:session:<sessionId>`가 남아 있는데 auth 확인 API는 계속 실패한다.
- direct auth-service 호출 `/auth/session`, `/auth/internal/session/validate`도 같은 `security.auth.required`를 반환한다.

#### 원인
- 웹 요청에서 `sso_session`보다 `ACCESS_TOKEN`이 먼저 선택되면 브라우저 세션 흐름이 JWT 검증 흐름으로 잘못 들어갈 수 있다.
- auth-service의 세션 validate 엔드포인트가 쿠키 기반 세션을 복원하지 못하면 Gateway가 연쇄적으로 401을 낸다.
- 따라서 “쿠키가 있다”와 “Gateway가 세션을 복원했다”는 같은 뜻이 아니다.

#### 확인
- `repositories/gateway-service/auth.md`
- `repositories/gateway-service/auth-flow.md`
- `repositories/auth-service/README.md`
- `repositories/redis-service/README.md`

#### 조치
1. 브라우저 요청에 실제 `Cookie` 헤더가 붙는지 먼저 확인한다.
2. Redis에 `auth:session:<sso_session>`가 존재하는지 본다.
3. auth-service `/auth/session`과 `/auth/internal/session/validate`를 직접 호출해도 401인지 확인한다.
4. Gateway는 브라우저 채널에서 `sso_session`을 우선 사용하도록 유지한다.
5. auth-service 세션 validate가 불안정할 때는 Gateway가 Redis SSO session 또는 access-token claims로 fallback 할 수 있는지 함께 본다.

### 12. `authz-service` prod compose는 base 서비스를 override해야지 다른 서비스를 추가하면 안 된다
#### 증상
- `docker compose -f docker/compose.yml -f docker/prod/compose.yml config --services`에서 `authz-service` 외에 `permission-service`가 보인다.
- prod compose validation이 실패하거나 base 서비스와 prod 서비스가 따로 합쳐진다.

#### 원인
- base compose 서비스 이름은 `authz-service`인데 prod override 파일이 다른 이름을 쓰면 override가 아니라 신규 서비스 추가가 된다.

#### 확인
- `repositories/authz-service/README.md`
- `repositories/authz-service/ops.md`

#### 조치
1. `docker/prod/compose.yml`의 서비스 이름은 base compose와 같은 `authz-service`를 사용한다.
2. prod 파일에는 override에 필요한 값만 추가하고, build context/image/네트워크의 기본 뼈대는 base compose를 그대로 상속한다.

### 13. auth-service prod Docker 경로는 run script가 `.env.prod`를 compose interpolation에 올리지 않으면 바로 깨진다
#### 증상
- `./scripts/run.docker.sh up prod`가 compose interpolation 단계에서 `AUTH_SERVICE_HOST_BIND is required` 같은 오류로 실패한다.
- `.env.prod`가 있어도 required 값이 비어 있는 것처럼 보인다.

#### 원인
- compose interpolation은 `env_file:`이 아니라 shell env 또는 `docker compose --env-file` 기준으로 처리된다.
- prod compose가 `AUTH_SERVICE_HOST_BIND`를 required로 요구하는데, run script가 `.env.prod`를 interpolation용으로 올리지 않으면 compose 단계에서 먼저 실패한다.

#### 확인
- `repositories/auth-service/README.md`
- `repositories/auth-service/ops.md`

#### 조치
1. run script는 `docker compose --env-file "$PROJECT_ROOT/.env.prod"` 또는 동등한 방식으로 `.env.prod`를 interpolation에 올린다.
2. `.env.prod`에는 `AUTH_SERVICE_HOST_BIND` 같은 required 값을 실제로 넣는다.
3. prod compose의 기본 `env_file` 상대경로도 서비스 루트 `.env.prod`를 가리키게 맞춘다.

### 14. editor-service prod Docker 경로는 env 파일과 GitHub Packages secret이 둘 다 준비돼야 한다
#### 증상
- `./scripts/run.docker.sh up prod`가 `EDITOR_SERVICE_HOST_BIND is required` 또는 `JWT_SECRET is required`에서 실패한다.
- clean machine에서 prod build가 private package download 단계에서 실패한다.

#### 원인
- prod compose는 required interpolation 값과 `JWT_SECRET`를 요구한다.
- Dockerfile은 GitHub Packages 인증을 `gh_token`, `github_actor` secret mount로 기대한다.
- run script가 `.env.prod` 또는 대체 env 파일을 compose interpolation에 올리지 않거나, prod compose build에 secrets를 안 넘기면 둘 중 하나에서 막힌다.

#### 확인
- `repositories/editor-service/README.md`
- `repositories/editor-service/ops.md`

#### 조치
1. run script는 `.env.prod`가 있으면 그것을, 없으면 최소한 `.env.example` 같은 대체 env를 `--env-file`로 읽을 수 있어야 한다.
2. prod compose build에도 `gh_token`, `github_actor` secret을 전달한다.
3. prod에서 required로 쓰는 `EDITOR_SERVICE_HOST_BIND`, `JWT_SECRET`는 추적 가능한 예시 파일 또는 배포 secret 관리 기준에 반드시 포함한다.

### 15. redis prod는 password 정책을 정하지 않고 빈 값으로 두면 compose 단계에서 멈춘다
#### 증상
- `redis-service` prod compose가 시작도 못 하고 `REDIS_PASSWORD is required`로 실패한다.

#### 원인
- prod compose는 Redis server와 exporter 모두 `REDIS_PASSWORD`를 required로 요구한다.
- `env.docker.prod`가 빈 값을 제공하면 run script가 그 값을 그대로 interpolation에 넣는다.

#### 확인
- `repositories/redis-service/README.md`
- `repositories/redis-service/ops.md`

#### 조치
1. prod env 파일에는 비어 있지 않은 `REDIS_PASSWORD`를 넣는다.
2. 만약 비밀번호 없는 private network Redis를 의도한다면, compose required 제약과 exporter 설정도 그 정책에 맞게 같이 바꾼다.

### 16. editor-service 런타임 정체성 문제를 다시 제보받으면 먼저 stale branch인지 확인한다
#### 증상
- 누군가 editor-service가 아직 `documents-app` 이름으로 돈다고 보고한다.
- JWT issuer/audience, audit service name, monitoring label이 모두 `documents-app`이라고 주장한다.

#### 원인
- 과거 브랜치나 압축본 기준 제보일 수 있다.
- 현재 main 기준 런타임 정체성이 이미 `editor-service`로 정리돼 있으면, 남은 문제는 다른 브랜치 또는 오래된 산출물일 가능성이 크다.

#### 확인
- `repositories/editor-service/README.md`
- `repositories/editor-service/ops.md`

#### 조치
1. 먼저 현재 main의 `application.yml`, `application-auth.yml`, `application-prod.yml`에서 `spring.application.name`, issuer, audience, audit service name을 다시 본다.
2. main이 이미 `editor-service`로 정렬돼 있으면 stale branch 보고로 분류하고, 실제 운영 산출물이 어디서 빌드됐는지부터 확인한다.

### 17. platform 릴리스만 올리고 서비스 구현을 그대로 두면 SOT와 코드가 다시 벌어진다
#### 증상
- registry 문서는 여전히 `2.0.5 / 2.0.2 / 2.0.2 / 1.0.3`를 적고 있는데, 서비스 구현 레포는 이미 `3.x` baseline으로 넘어갔다.
- 문서에는 gateway가 `platform-security-core`, `platform-security-web`를 직접 본다고 적혀 있는데 실제 구현은 `platform-security-hybrid-web-adapter`와 service-owned `HybridSecurityRuntime` 기준이다.
- editor-service가 아직 `platform-resource-core`를 직접 손댄다고 적혀 있는데 실제 구현은 runtime `platform-resource-support-local`로 local backing을 받는다.

#### 원인
- platform 버전 갱신과 서비스 구현 정리를 별개 작업으로 처리해 contract만 먼저 바꾸거나, 반대로 구현만 바꾸고 contract를 안 바꾼다.
- 특히 gateway, authz, editor처럼 sanctioned add-on과 compat 경로가 있는 서비스는 구현 변경 후 문서 드리프트가 빠르게 생긴다.

#### 확인
- `registry/module-ecosystem.md`
- `repositories/gateway-service/README.md`
- `repositories/auth-service/README.md`
- `repositories/user-service/README.md`
- `repositories/authz-service/README.md`

#### 조치
1. 구현 레포 기준 현재 baseline은 `auth/user/authz/gateway = platform-runtime-bom 3.0.1`, `editor = runtime-bom 3.0.1 + governance/security/resource 3.0.0 + bridges 2.0.0`으로 기록한다.
2. Gateway는 `platform-security-hybrid-web-adapter`와 service-owned `GatewayPlatformSecurityWebFilter`, `HybridSecurityRuntime`을 함께 쓰는 현재 구조로 적는다.
3. Auth-service는 `platform-security-auth-bridge-starter`, `platform-security-ratelimit-bridge-starter`를, User-service는 `platform-security-ratelimit-bridge-starter`를 소비한다고 적는다.
4. Authz-service는 `platform-security-legacy-compat`, `platform-security-web-api`, `AuthzInternalRequestAuthorizer` 기반 `HYBRID` internal auth compat를 유지한다고 적는다.
5. Editor-service는 `platform-resource-support-local` runtime fallback과 `platform-security-web-api` 기반 custom failure writer를 쓰는 현재 구조로 적는다.

### 18. platform-governance 공식 SPI는 `AuditSink`이고, 서비스 도메인 audit는 `AuditLogger` 또는 `AuditSink`를 우선한다
#### 증상
- prod 운영 설정에는 `AuditSink` bean이 있는데, 도메인 서비스 코드나 문서는 여전히 `AuditLogRecorder` 직접 주입을 기준으로 설명한다.
- 서비스 개발자가 `AuditLogRecorder`를 공식 sink SPI로 오해한다.

#### 원인
- 현재 `AuditLogRecorder`는 mainline starter surface가 아니라 `platform-governance-adapter-auditlog` 쪽 bridge/test/compat adapter다.
- 이전 구현이 `AuditLogRecorder`를 직접 사용하던 시기의 문서가 남아 있을 수 있다.

#### 확인
- `registry/module-ecosystem.md`
- `repositories/auth-service/README.md`
- `repositories/user-service/README.md`
- `repositories/authz-service/README.md`

#### 조치
1. 운영 sink SPI는 `AuditSink`로 본다.
2. 서비스 도메인 audit 구현은 `AuditLogger` 또는 `AuditSink`를 우선 사용한다.
3. `AuditLogRecorder`는 `platform-governance-adapter-auditlog`에 있는 bridge/test/compat adapter로 설명하고, 새 서비스 구현의 기본 선택지로 적지 않는다.

### 19. editor-page base URL에 `/v1`를 넣으면 요청 경로가 `/v1/v1/...`로 깨진다
#### 증상
- editor-page에서 auth, document, save 요청이 전부 `404` 또는 잘못된 경로로 실패한다.
- 네트워크 탭을 보면 `http://localhost:8080/v1/v1/auth/me`, `/v1/v1/documents`, `/v1/v1/editor-operations/...`처럼 `/v1`가 두 번 붙는다.

#### 원인
- current editor-page 구현은 base URL에 `/v1`를 넣지 않고, endpoint 상수 쪽에 `/v1/**`를 포함하는 방식이다.
- `VITE_GATEWAY_BASE_URL` 또는 `VITE_API_BASE_URL`에 `/v1`를 붙이면 endpoint 상수와 중복된다.

#### 확인
- `repositories/editor-page/README.md`

#### 조치
1. `VITE_GATEWAY_BASE_URL`, `VITE_API_BASE_URL`, `VITE_DOCUMENTS_API_BASE_URL`은 `http://localhost:8080`처럼 Gateway origin만 넣는다.
2. `/v1` prefix는 endpoint 상수에서만 붙인다.
3. 네트워크 탭에서 최종 URL이 `http://<gateway-origin>/v1/...` 한 번만 조립되는지 확인한다.

### 20. editor-page가 Gateway 대신 backend를 직접 호출하면 local에서는 붙어도 계약상 바로 drift가 난다
#### 증상
- 어떤 화면은 되는데 어떤 화면은 CORS, cookie, path rewrite 문제로 자주 깨진다.
- 브라우저가 `auth-service`, `editor-service`, `user-service`를 직접 호출하도록 임시 수정한 뒤 로그인과 저장 동작이 불안정해진다.

#### 원인
- current browser contract는 Gateway public `/v1/**`만 직접 호출하는 구조다.
- backend direct 호출로 바꾸면 CORS, trusted header, cookie path/domain, public/upstream route 차이를 프런트가 직접 떠안게 된다.

#### 확인
- `repositories/editor-page/README.md`
- `shared/routing.md`
- `repositories/gateway-service/README.md`

#### 조치
1. 브라우저에서는 Gateway만 직접 호출한다.
2. `auth-service`, `editor-service`, `user-service` 직접 호출은 local debug나 내부 서버 통신 문맥으로만 제한한다.
3. editor-page 환경변수와 API 클라이언트가 최종적으로 `http://<gateway-origin>/v1/...`만 치는지 확인한다.

### 21. editor-page save와 move는 Gateway public `/v1/editor-operations/**`를 써야지 service 내부 path와 섞으면 안 된다
#### 증상
- 문서 조회는 되는데 저장이나 이동만 `404`, `405`, `NOT_FOUND`로 떨어진다.
- 프런트가 `POST /v1/documents/{documentId}/transactions` 또는 `/documents/{documentId}/transactions` 같은 경로를 호출한다.
- move를 `/v1/documents/{documentId}/move`나 block admin path로 잘못 보내는 경우가 있다.

#### 원인
- current Gateway 외부 공개 route는 `/v1/editor-operations/**`이고, editor-page도 그 경로를 소비한다.
- editor-service 문서 안에는 service 내부 경로 설명과 transaction 개념 설명이 함께 있어, 브라우저 public route와 upstream/internal route를 혼동하기 쉽다.

#### 확인
- `repositories/editor-page/README.md`
- `repositories/editor-service/api.md`
- `repositories/gateway-service/README.md`

#### 조치
1. editor-page 저장은 `POST /v1/editor-operations/documents/{documentId}/save`를 사용한다.
2. editor-page 이동은 `POST /v1/editor-operations/move`를 사용한다.
3. `/documents/{documentId}/transactions`, `/documents/{documentId}/move`, `/admin/**`는 브라우저 public route와 같은 레벨로 취급하지 않는다.

### 22. editor-page 기능 추가 전에는 현재 서버 지원 범위를 먼저 고정해야 한다
#### 증상
- heading picker, multi-block action, group move 같은 기능을 붙였는데 일부만 저장되고 일부는 validation 또는 contract mismatch로 실패한다.
- 프런트는 기능을 추가했으니 서버도 비슷하게 받아줄 것이라고 가정하지만, 실제 payload shape와 지원 범위가 다르다.

#### 원인
- current v1에서 rich-text subtype 추가는 optional `content.blockType`으로만 지원한다.
- `segment`는 `text`, `marks`만 허용한다.
- transaction batch는 여러 단건 operation의 순차 적용일 뿐, 여러 블록 selection 자체를 표현하지 않는다.
- 여러 블록 delete나 subtype 일괄 변경은 클라이언트가 여러 operation으로 조립할 수 있지만, 여러 블록의 상대 순서를 보존한 bulk move는 아직 별도 계약이 없다.

#### 확인
- `repositories/editor-page/README.md`
- `repositories/editor-service/schema-v1.md`
- `repositories/editor-service/rules-v1.md`
- `repositories/editor-service/operations.md`

#### 조치
1. heading 계열 기능은 `content.blockType=paragraph|heading1|heading2|heading3` 범위로만 보낸다.
2. `segment.type`, `segment.blockType`, `selectedBlockIds`, `groupMove` 같은 필드를 현재 v1 request에 임의로 추가하지 않는다.
3. 여러 블록 delete나 subtype 일괄 변경은 여러 `BLOCK_DELETE` 또는 `BLOCK_REPLACE_CONTENT` operation으로 batch를 조립한다.
4. 여러 선택 블록의 상대 순서를 유지한 bulk move가 필요하면 새 request, validation, response 계약부터 추가한다.

### 23. undo/redo를 서버 history나 restore API처럼 기대하면 저장 이후 UX가 바로 어긋난다
#### 증상
- editor-page에 undo/redo를 붙였는데 새로고침 후에는 직전 편집 취소가 안 된다.
- 다른 탭이나 다른 브라우저에서 방금 한 수정까지 undo/redo 되길 기대한다.
- delete 후 바로 복구는 되는데, 저장 후 세션이 바뀌면 같은 동작이 안 돼서 버그처럼 보인다.

#### 원인
- current editor 계약에서 같은 브라우저 세션 안의 직전 삭제/수정 복구는 클라이언트 undo/redo가 담당한다.
- v1에는 block 단위 server restore API나 서버 소유 undo/redo history API가 없다.
- 서버는 최종 save batch 반영만 소유하고, 편집기의 세션별 history stack은 소유하지 않는다.

#### 확인
- `repositories/editor-service/rules-v1.md`
- `repositories/editor-service/operations.md`
- `repositories/editor-service/api.md`

#### 조치
1. undo/redo는 editor-page 로컬 상태와 로컬 queue 기준으로 구현한다.
2. 새로고침, 탭 전환, 다른 디바이스까지 이어지는 공용 history를 기대하지 않는다.
3. 저장 이후에도 같은 브라우저 세션에서만 취소/재실행 UX를 유지하고, 서버에는 최종 batch만 반영한다.
4. 서버 복구가 필요하면 undo/redo가 아니라 별도 restore/history 계약을 새로 정의한다.

### 24. 입력 단위를 batch로 묶어 UX를 높였으면 저장 시점과 로컬 반영 시점을 분리해서 이해해야 한다
#### 증상
- 타이핑할 때 UI는 즉시 반응하는데 서버 저장은 나중에 일어나서 “입력이 씹힌다”는 오해가 생긴다.
- autosave, `Ctrl+S`, page leave가 서로 다른 저장 기능처럼 다뤄져 중복 호출이나 경쟁 상태가 생긴다.
- 같은 블록을 여러 번 수정하거나 이동했는데 서버에는 마지막 상태만 반영되어 디버깅 시 혼란이 생긴다.

#### 원인
- current editor save 모델은 입력 이벤트마다 서버를 호출하지 않고, 로컬 상태를 먼저 바꾼 뒤 queue에서 의미 없는 중간 변경을 상쇄/병합해 최종 batch만 보낸다.
- autosave와 `Ctrl+S`는 서로 다른 API가 아니라 같은 queue flush 트리거다.
- debounce만으로 무한정 저장을 미루지 않기 위해 `max autosave interval` 기준 강제 flush를 둔다.

#### 확인
- `repositories/editor-service/operations.md`
- `repositories/editor-service/rules-v1.md`
- `repositories/editor-page/README.md`

#### 조치
1. editor-page는 입력 즉시 로컬 UI를 반영하고, 서버 반영은 save batch flush 시점으로 분리한다.
2. autosave, `Ctrl+S`, page leave는 같은 queue를 flush하는 서로 다른 트리거로만 취급한다.
3. 같은 flush 전에 생긴 `create -> replace -> delete`, 연속 content 수정, 연속 move 같은 중간 상태는 queue에서 상쇄/병합한다.
4. 서버에 “모든 입력 이벤트”가 아니라 “현재까지 반영할 가치가 있는 최종 batch”만 보내는 것이 정상 동작임을 기준으로 본다.
### 25. trash 문서 완전 삭제가 404로 떨어지면 `delete()`가 active 문서만 찾는지 먼저 본다

- 증상:
  - FE에서 휴지통 문서 완전 삭제로 `DELETE /v1/documents/{documentId}`를 호출했는데 `404 Not Found`가 난다.
  - 같은 문서는 `GET /v1/documents/trash` 목록에는 보인다.
- 원인:
  - `DocumentServiceImpl.delete()`가 `findActiveDocument(documentId)`를 쓰면 `deletedAt != null`인 trash 문서를 바로 `DOCUMENT_NOT_FOUND`로 처리한다.
  - 계약상 `DELETE /documents/{documentId}`는 존재해도 구현이 active 문서만 전제하면 trash purge가 불가능하다.
- 확인 포인트:
  - `delete()` 시작부가 `findByIdAndDeletedAtIsNull(...)` 또는 `findActiveDocument(...)`를 타는지 본다.
  - purge 대상 resource binding scheduling이 active tree 기준으로만 계산되는지 본다.
- 수정:
  - `delete()`에서 문서는 `documentRepository.findById(documentId)`로 먼저 찾는다.
  - 문서가 active면 `collectActiveDocumentTreeIds(document)`를 쓰고,
  - trash면 `collectDeletedDocumentTreeIds(document)`를 써서 purge 대상 ID를 잡는다.
  - 그 다음은 지금처럼 `scheduleDocumentBindingsForPurge(...)` 후 `documentRepository.delete(document)`를 유지한다.
- 테스트:
  - service test에 `trash 문서 delete` 케이스를 추가한다.
  - integration test에 `PATCH /documents/{id}/trash -> DELETE /documents/{id}` 성공 케이스를 추가한다.

### 26. editor-page save가 400으로 보일 때 실제 원인이 `BLOCK_DELETE`의 MySQL 1093인지 먼저 본다

#### 증상
- 브라우저 네트워크 탭에서는 `POST /v1/editor-operations/documents/{documentId}/save`가 `400 Bad Request`처럼 보인다.
- 단순 `BLOCK_REPLACE_CONTENT`는 되는데, 빈 블록 삭제나 block delete가 섞인 save batch에서만 저장이 실패한다.
- FE payload shape는 얼핏 정상인데 저장이 안 된다.

#### 원인
- 실제 실패 지점이 request validation이 아니라 block soft delete bulk update일 수 있다.
- `BlockRepository.softDeleteActiveByIdsWithRootVersion(...)`처럼 `update blocks ... where exists (select ... from blocks ...)` 형태로 같은 테이블을 subquery에서 다시 참조하면 MySQL에서 `SQL Error 1093: You can't specify target table ... for update in FROM clause`가 난다.
- Gateway/FE에서는 최종적으로 generic `400` 또는 저장 실패처럼만 보일 수 있어서 request shape 문제로 오해하기 쉽다.

#### 확인
- `docker logs` 또는 service 로그에서 `SQL Error: 1093`, `You can't specify target table`가 찍히는지 본다.
- 같은 문서에 대해 수동 `BLOCK_REPLACE_CONTENT` save는 성공하고 `BLOCK_DELETE` save만 실패하는지 본다.
- 실패 시점의 repository bulk update가 같은 `blocks` 테이블을 subquery에서 다시 참조하는지 본다.

#### 조치
1. `BLOCK_DELETE`는 root block CAS 삭제와 descendant soft delete를 한 번의 same-table subquery bulk update로 처리하지 않는다.
2. root는 `softDeleteRootByIdAndVersion(rootId, rootVersion, actorId, deletedAt)`처럼 별도 update로 먼저 처리한다.
3. root update row count가 `0`이면 `CONFLICT`로 본다.
4. descendant는 `softDeleteActiveDescendantsByIds(blockIds, rootId, actorId, deletedAt)`처럼 root 제외 bulk update로 따로 처리한다.
5. service는 기존처럼 subtree ID 수집, attachment purge scheduling, document version 증가 흐름을 유지한다.

#### 테스트
- `BlockServiceImplTest`에 root-first delete 경로 검증을 추가하거나 갱신한다.
- `EditorOperationApiIntegrationTest`의 existing block delete 성공 케이스가 실제 DB에서 통과하는지 확인한다.
- 로컬 dev docker 재기동 후 `POST /v1/editor-operations/documents/{documentId}/save` + `BLOCK_DELETE` 수동 요청으로 다시 확인한다.

### 27. gateway-service CI prod compose validation은 placeholder env를 비워 두면 `GATEWAY_INTERNAL_JWT_SHARED_SECRET is required`로 바로 멈춘다

#### 증상
- GitHub Actions `Validate Compose config` 단계가 `touch "$RUNNER_TEMP/gateway-empty.env"` 직후 실패한다.
- 로그에 `required variable GATEWAY_INTERNAL_JWT_SHARED_SECRET is missing a value`가 찍힌다.
- dev compose config 검증은 통과하는데 prod compose config 검증만 실패한다.

#### 원인
- `service-gateway/.github/workflows/ci.yml`의 `COMPOSE_CONFIG_COMMAND`가 빈 env 파일을 만든 뒤 prod compose required 값을 inline shell env로 일부만 채운다.
- 그런데 `service-gateway/docker/prod/compose.yml`은 `GATEWAY_INTERNAL_JWT_SHARED_SECRET`를 `:?` required로 강제하는데, CI 명령이 그 값을 안 올리고 있었다.
- 반대로 `service-gateway/docker/dev/compose.yml`은 같은 값을 dev 기본값으로 fallback하므로 dev 검증은 통과한다.
- 같은 저장소의 `service-gateway/.github/workflows/cd.yml`에는 이미 placeholder 값이 있었기 때문에 CI와 CD가 서로 drift 난 상태였다.

#### 확인
- `service-gateway/.github/workflows/ci.yml`
- `service-gateway/.github/workflows/cd.yml`
- `service-gateway/docker/prod/compose.yml`
- `service-gateway/docker/dev/compose.yml`
- `repositories/gateway-service/env.md`

#### 조치
1. CI prod compose validation 명령에 `GATEWAY_INTERNAL_JWT_SHARED_SECRET=ci-gateway-internal-jwt-secret` 같은 placeholder 값을 추가한다.
2. CI와 CD의 prod compose validation env set를 같은 기준으로 맞춘다.
3. `touch "$RUNNER_TEMP/gateway-empty.env"` 자체는 유지해도 되지만, prod `:?` required 값은 모두 shell env 또는 `--env-file`로 interpolation 단계에 올려야 한다.
4. 재검증은 GitHub Actions의 `Validate Compose config` 단계 또는 같은 `docker compose -f docker/compose.yml -f docker/prod/compose.yml config` 명령으로 한다.

### 28. `grafana.myeditor.n-e.kr`는 문서에 있어도 DNS가 없으면 접속 전에 `Could not resolve host`로 막힌다

#### 증상
- 브라우저나 `curl`에서 `grafana.myeditor.n-e.kr` 접속 시 DNS 해석 실패가 난다.
- `myeditor.n-e.kr`, `api.myeditor.n-e.kr`는 열리는데 Grafana 서브도메인만 안 열린다.
- 운영 문서에는 Grafana 공개 호스트가 있는데 실제 공개 주소는 없어서 혼란이 생긴다.

#### 원인
- `service-contract`의 edge routing/Nginx 예시는 `grafana.myeditor.n-e.kr`를 공개 엔드포인트로 정의하지만, 실제 DNS 레코드가 없으면 외부 클라이언트는 Nginx까지 도달하지 못한다.
- Grafana 컨테이너는 기본적으로 `127.0.0.1:3005` bind라서 direct host port 공개가 아니라 DNS + Nginx reverse proxy가 전제다.

#### 확인
- `shared/single-ec2-edge-routing.md`
- `templates/single-ec2/nginx.single-ec2.conf.example`
- `templates/single-ec2/env/monitoring-service.env.prod.example`
- `dig +short myeditor.n-e.kr`
- `dig +short grafana.myeditor.n-e.kr`

#### 조치
1. `grafana.myeditor.n-e.kr`를 현재 edge EC2/Nginx와 같은 public IP 또는 EIP로 향하게 `A` 레코드 또는 동등한 `CNAME`으로 등록한다.
2. 이미 `*.myeditor.n-e.kr` 와일드카드 DNS가 있으면 별도 레코드가 필요 없는지 먼저 확인한다.
3. DNS 등록 후에는 `curl -I http://grafana.myeditor.n-e.kr` 또는 브라우저로 실제 Nginx 응답까지 확인한다.
4. DNS만 맞춰도 HTTPS는 별도 문제일 수 있으므로 TLS 인증서와 `443` server block을 이어서 본다.

### 29. `grafana.myeditor.n-e.kr`는 HTTP는 `/login`까지 가도 TLS SAN과 `443` server block이 없으면 HTTPS가 깨진다

#### 증상
- `http://grafana.myeditor.n-e.kr`는 `302 /login`으로 보이는데 `https://grafana.myeditor.n-e.kr`는 인증서 오류가 난다.
- `curl` 기준 `SSL: no alternative certificate subject name matches target host name 'grafana.myeditor.n-e.kr'`가 찍힌다.
- 경우에 따라 `443`에서 잘못된 가상호스트로 떨어져 `404` JSON 같은 엉뚱한 응답이 보인다.

#### 원인
- 활성 Nginx 설정에 `grafana.myeditor.n-e.kr`용 `listen 80` server block만 있고 `listen 443 ssl` server block이 없을 수 있다.
- 기존 Certbot 인증서 `myeditor.n-e.kr`가 `myeditor.n-e.kr`, `api.myeditor.n-e.kr`, `editor.myeditor.n-e.kr`만 SAN에 포함하고 `grafana.myeditor.n-e.kr`는 빠져 있을 수 있다.
- 즉 DNS가 살아 있어도 Nginx HTTPS 라우팅과 인증서 SAN이 같이 맞지 않으면 Grafana HTTPS는 정상 공개가 아니다.

#### 확인
- `sudo nginx -T`
- `sudo certbot certificates`
- `/etc/nginx/conf.d/myeditor.conf`
- `curl -I http://grafana.myeditor.n-e.kr`
- `curl -I https://grafana.myeditor.n-e.kr`

#### 조치
1. Grafana upstream은 계속 `http://127.0.0.1:3005`를 사용하고, 외부 공개는 Nginx가 맡게 둔다.
2. Certbot을 쓰는 서버라면 기존 cert name을 그대로 확장해서 `grafana.myeditor.n-e.kr`를 SAN에 추가한다.
3. 예시는 `sudo certbot --nginx --cert-name myeditor.n-e.kr -d myeditor.n-e.kr -d api.myeditor.n-e.kr -d editor.myeditor.n-e.kr -d grafana.myeditor.n-e.kr --expand --redirect --non-interactive`다.
4. 적용 후 `sudo certbot certificates`에서 SAN 목록에 `grafana.myeditor.n-e.kr`가 보이고, `sudo nginx -T`에 `grafana`용 `listen 443 ssl`과 `80 -> 443` redirect가 생성됐는지 확인한다.
5. 최종 검증은 `curl -I https://grafana.myeditor.n-e.kr`가 인증서 오류 없이 `302 /login` 또는 Grafana 로그인 화면 응답을 반환하는지로 한다.

### 30. gateway-service EC2 CD가 전체 stack `pull`을 돌리면 gateway와 무관한 Docker Hub 이미지 timeout으로도 실패할 수 있다

#### 증상
- gateway-service CD에서 ECR login과 gateway image pull은 성공했는데, 배포 단계 중간에 `mysql:8.0` 또는 다른 서드파티 이미지 pull에서 실패한다.
- 로그에 `Image mysql:8.0 Error Head "https://registry-1.docker.io/v2/library/mysql/manifests/8.0"` 또는 `auth.docker.io/token` timeout이 찍힌다.
- 실패 로그를 보면 `prod-gateway-service:<sha>`는 이미 `Pulled`인데, 전체 배포 job은 실패로 끝난다.

#### 원인
- gateway-service repo의 EC2 CD가 원격에서 `./scripts/deploy-stack.sh up`를 호출하면, deploy bundle 스크립트가 `backend pull`과 `frontend pull`로 전체 스택 이미지를 다시 당긴다.
- 이때 gateway 배포와 무관한 `mysql:8.0`, `mysql:8.4`, `oliver006/redis_exporter` 같은 외부 registry 이미지까지 함께 pull된다.
- 따라서 gateway 이미지 자체는 정상이어도 Docker Hub 네트워크 지연이나 token endpoint timeout 때문에 배포 전체가 실패할 수 있다.

#### 확인
- `templates/single-ec2/deploy-bundle/scripts/deploy-stack.sh`
- `templates/single-ec2/deploy-bundle/docker-compose.backend.yml`
- `service-gateway/.github/workflows/cd.yml`
- EC2에서 `grep '^GATEWAY_IMAGE=' /opt/deploy/.env.backend`
- EC2에서 `docker compose --env-file /opt/deploy/.env.backend -f /opt/deploy/docker-compose.backend.yml ps gateway-service`

#### 조치
1. gateway-service CD는 전체 stack deploy script 대신 `gateway-service`만 대상으로 `docker compose pull gateway-service && docker compose up -d gateway-service`를 호출한다.
2. pull과 up는 각각 한 번 정도 retry를 둘 수 있다.
3. 이렇게 바꾸면 gateway 배포가 unrelated MySQL/Grafana/Redis exporter pull 실패에 영향을 덜 받는다.
4. 근본적으로는 서드파티 운영 이미지를 ECR mirror 또는 사내 registry로 옮기는 것도 검토한다.
5. 실패 run 이후에도 실제 EC2의 `.env.backend`와 `gateway-service` 컨테이너가 이미 새 이미지로 올라갔을 수 있으니, job 결과만 보지 말고 서버 상태를 같이 확인한다.

### 31. `GET /v1/auth/sso/start`가 `1012 업스트림 호출 실패`로 떨어지면 auth-service 자체보다 auth-service의 prod env를 먼저 본다

#### 증상
- `https://api.myeditor.n-e.kr/v1/auth/sso/start`가 `502` 또는 `1012`를 반환한다.
- explain-page나 editor-page에서 로그인 버튼을 누르면 GitHub로 가지 못하고 바로 실패한다.
- gateway 로그에는 `path=/v1/auth/sso/start upstream=auth`까지만 남는다.

#### 원인
- auth-service prod env에서 `MYSQL_URL`이 빠졌거나 `allowPublicKeyRetrieval=true`가 없어 MySQL 연결에 실패할 수 있다.
- `INTERNAL_API_KEY` 같은 내부 호출용 키가 빠지면 auth-service가 prod 기동 중 바로 죽을 수 있다.
- `SSO_EXPLAIN_CALLBACK_URI`, `SSO_EDITOR_CALLBACK_URI`가 비어 있으면 `/auth/sso/start`가 redirect URL을 만들지 못하고 실패한다.

#### 확인
- EC2 `/opt/deploy/.env.backend`
- `docker logs single-ec2-backend-auth-service-1`
- `curl -i "https://api.myeditor.n-e.kr/v1/auth/sso/start?page=explain&redirect_uri=https://myeditor.n-e.kr/auth/callback"`

#### 조치
1. `MYSQL_URL=jdbc:mysql://auth-mysql:3306/authdb?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC`처럼 auth 전용 DB URL을 명시한다.
2. `INTERNAL_API_KEY`를 auth 내부 호출 시크릿과 같은 값으로 맞춘다.
3. `SSO_EXPLAIN_CALLBACK_URI=https://myeditor.n-e.kr/auth/callback`, `SSO_EDITOR_CALLBACK_URI=https://editor.myeditor.n-e.kr/auth/callback`를 채운다.
4. 수정 후 `auth-service`, `gateway-service`를 함께 재기동하고 `/v1/auth/sso/start`가 `302`로 바뀌는지 확인한다.

### 32. GitHub OAuth에서 `The redirect_uri is not associated with this application`가 뜨면 callback URI의 `http/https`와 GitHub App 설정이 어긋난다

#### 증상
- GitHub 로그인 화면에서 바로 `The redirect_uri is not associated with this application.`가 뜬다.
- auth start는 `302`로 가지만 GitHub authorize 단계에서 막힌다.

#### 원인
- auth-service가 GitHub authorize URL을 만들 때 `http://api.myeditor.n-e.kr/...`를 넣고 있는데 GitHub OAuth App에는 `https://api.myeditor.n-e.kr/...`만 등록돼 있을 수 있다.
- `SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GITHUB_REDIRECT_URI`가 빠지면 프레임워크 기본 계산값으로 `http` callback이 나갈 수 있다.

#### 확인
- `docker logs single-ec2-backend-auth-service-1`
- EC2 `/opt/deploy/.env.backend`
- `curl -k -sS -L --max-redirs 2 -D - -o /dev/null "https://api.myeditor.n-e.kr/v1/auth/sso/start?page=explain&redirect_uri=https%3A%2F%2Fmyeditor.n-e.kr%2Fauth%2Fcallback"`
- GitHub OAuth App 설정

#### 조치
1. GitHub OAuth App의 `Authorization callback URL`을 `https://api.myeditor.n-e.kr/v1/login/oauth2/code/github`로 고정한다.
2. auth-service env에도 `SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GITHUB_REDIRECT_URI=https://api.myeditor.n-e.kr/v1/login/oauth2/code/github`를 넣는다.
3. `SSO_GITHUB_CALLBACK_URI`도 같은 값으로 맞춘다.
4. 재기동 후 GitHub authorize URL에 실리는 `redirect_uri`가 `https://api...`인지 다시 확인한다.

### 33. 로그인 후 `oauth2 failed`가 뜨면 callback 이후 user-service가 `dev` 프로필로 뜨는지 먼저 본다

#### 증상
- GitHub 로그인과 callback은 끝났는데 최종 화면에 `oauth2 failed`가 뜬다.
- auth-service 로그에는 `user-service 연동 실패`가 남는다.

#### 원인
- user-service가 운영 배포에서도 `dev` 프로필로 뜨면 platform governance / audit env와 충돌해 기동 직후 죽을 수 있다.
- 그 상태에서 auth-service의 callback success handler가 사용자 정보를 조회하다가 실패한다.

#### 확인
- `docker logs single-ec2-backend-user-service-1`
- `docker exec single-ec2-backend-auth-service-1 curl -i http://user-service:8082/actuator/health`
- `/opt/deploy/docker-compose.backend.yml`의 `user-service.environment`

#### 조치
1. deploy bundle의 `user-service`에 `SPRING_PROFILES_ACTIVE: prod`를 명시한다.
2. `user-service`, `auth-service`, `gateway-service`를 순서대로 재기동한다.
3. auth-service 컨테이너 안에서 `http://user-service:8082/actuator/health`가 `200 UP`인지 본다.
4. 그 다음 OAuth start -> callback 흐름을 다시 검증한다.

### 34. explain-page 로그인 완료 후 editor로 안 넘어가면 callback host와 성공 후 redirect host를 분리해서 본다

#### 증상
- explain-page에서 로그인은 되는데 계속 `https://myeditor.n-e.kr`에만 머문다.
- 시작하기 버튼을 눌러도 editor가 아니라 explain 쪽 로그인만 반복된다.

#### 원인
- explain-page 빌드 시점 env에 `NEXT_PUBLIC_START_FRONTEND_URL`, `NEXT_PUBLIC_SSO_CONSUMER_CALLBACK_URL`가 원하는 editor 도메인으로 안 들어갔을 수 있다.
- explain-page가 callback 자체를 처리하면 성공 후 same-origin redirect로 머무를 수 있다.
- editor-page는 별도 `/auth/callback`과 post-auth redirect 로직을 이미 가지고 있으므로, 실제 callback을 editor가 처리하는 흐름이 더 단순할 수 있다.

#### 확인
- `page-explain/.github/workflows/cd.yml`
- `page-explain/docker/Dockerfile`
- `page-explain/.env.production.example`
- 라이브 explain-page 컨테이너 내부 `.next/required-server-files.json`

#### 조치
1. explain-page build env의 `NEXT_PUBLIC_START_FRONTEND_URL`을 `https://editor.myeditor.n-e.kr`로 맞춘다.
2. explain-page build env의 `NEXT_PUBLIC_SSO_CONSUMER_CALLBACK_URL`을 `https://editor.myeditor.n-e.kr/auth/callback`로 맞춘다.
3. editor-page의 `/auth/callback`이 ticket exchange와 최종 이동을 맡도록 두고, explain-page는 로그인 시작만 담당하게 정리한다.
4. explain-page 새 이미지를 다시 빌드/배포한 뒤 라이브 컨테이너 안에 editor callback URL이 bake 되었는지 확인한다.

### 35. `/v1/documents`가 `502`면 gateway 라우팅보다 editor-service의 datasource 오염을 먼저 본다

#### 증상
- editor-page에서 문서 목록/생성이 `502 Bad Gateway`로 떨어진다.
- gateway 응답 바디는 `code=1012`, `message=업스트림 호출에 실패한 경우`다.
- gateway 로그에는 `path=/v1/documents upstream=editor`까지만 찍힌다.

#### 원인
- editor-service 자체는 `DB_URL_PROD`를 쓰도록 설계돼 있는데, 배포 번들의 공통 `.env.backend`에서 흘러온 `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`가 먼저 적용될 수 있다.
- 그 값이 user-service용 `jdbc:mysql://user-mysql:3306/user_service...`를 가리키면 editor-service가 자기 전용 MySQL(`editor-mysql`) 대신 잘못된 DB로 붙으려다 부팅에 실패한다.
- 결과적으로 gateway는 살아 있지만 editor upstream이 재기동 루프에 들어가며 `502`가 난다.

#### 확인
- `docker logs editor-service-prod`
- `docker inspect editor-service-prod --format '{{json .Config.Env}}'`
- `docker compose --env-file /opt/deploy/.env.backend -f /opt/deploy/docker-compose.backend.yml config`
- `docker network inspect single-ec2-backend_editor-private`

#### 조치
1. deploy bundle `editor-service.environment`에 아래 값을 명시적으로 override 한다.
   - `SPRING_DATASOURCE_URL=${DB_URL_PROD:-jdbc:mysql://editor-mysql:3306/${DB_NAME_PROD:-documentsdb}...}`
   - `SPRING_DATASOURCE_USERNAME=${DB_USERNAME_PROD:-documents}`
   - `SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD_PROD:?DB_PASSWORD_PROD is required}`
2. 동시에 `DB_USERNAME_PROD`, `DB_PASSWORD_PROD`도 `editor-service` environment에 명시해 prod 키가 빠지지 않게 한다.
3. 수정 후 `editor-service`, `gateway-service`를 재기동한다.
4. 재검증 시 `/v1/documents`가 더 이상 `502`가 아니어야 한다. 인증 없이 직접 치면 정상적으로는 `401`이 나와야 upstream 장애가 해소된 것이다.

### 36. Route53에 레코드를 넣었는데도 HTTPS 발급이 안 되면 실제 등록 NS가 Route53인지부터 본다

#### 증상
- Route53 Hosted Zone에는 `myeditor.n-e.kr`, `api.myeditor.n-e.kr`, `editor.myeditor.n-e.kr` A 레코드가 있는데 `certbot`은 여전히 DNS 해석 실패를 낸다.
- `dig NS myeditor.n-e.kr` 결과가 Route53 NS가 아니라 다른 DNS 사업자를 가리킨다.

#### 원인
- Hosted Zone에 레코드를 넣는 것과 실제 공용 DNS 위임은 별개다.
- 도메인 등록업체의 NS가 Route53 NS로 바뀌지 않으면 외부 클라이언트와 Let’s Encrypt는 Route53 레코드를 보지 않는다.

#### 확인
- `dig NS myeditor.n-e.kr`
- Route53 Hosted Zone NS
- 도메인 등록업체의 네임서버 설정

#### 조치
1. 등록업체 NS를 Route53 Hosted Zone NS로 바꾸거나, 현재 사용 중인 외부 DNS에 동일한 A 레코드를 넣는다.
2. 세 호스트가 모두 같은 EC2/EIP를 가리키는지 확인한다.
3. DNS 전파 후 `sudo certbot --nginx -d myeditor.n-e.kr -d editor.myeditor.n-e.kr -d api.myeditor.n-e.kr`를 실행한다.
4. 발급 후 `curl -I https://myeditor.n-e.kr`, `curl -I https://editor.myeditor.n-e.kr`, `curl -I https://api.myeditor.n-e.kr/actuator/health`로 검증한다.

### 37. EC2 SSH가 안 붙을 때는 키보다 먼저 `Public IPv4`와 `Elastic IP`가 실제로 같은 인스턴스를 가리키는지 본다

#### 증상
- `ssh -v` 로그가 `Connecting to ... port 22`에서 오래 멈추거나 잘못된 IP에 붙는다.
- 같은 인스턴스인데 어떤 때는 `52.x.x.x`, 어떤 때는 `16.x.x.x`를 쓰고 있어 혼란이 생긴다.
- `ping`이 안 되거나 `Connection refused`가 뜬다.

#### 원인
- SSH config가 현재 인스턴스의 실제 접근 주소가 아니라 예전 `Public IPv4`를 보고 있을 수 있다.
- `Elastic IP`를 만들었어도 실제 인스턴스에 associate되지 않으면 접속 대상이 달라진다.
- `ping`은 막혀 있어도 SSH는 정상일 수 있어 네트워크 판단을 헷갈리게 만든다.

#### 확인
- AWS EC2 콘솔의 `Public IPv4 address`
- AWS EC2 콘솔의 `Elastic IP association`
- 로컬 `~/.ssh/config`
- `ssh -v ec2-user@<ip>`

#### 조치
1. 현재 인스턴스의 실제 접근 주소를 하나로 정한다. 보통 운영용이면 `Elastic IP`를 기준으로 삼는다.
2. `~/.ssh/config`의 `HostName`을 그 IP로 맞춘다.
3. `Elastic IP`를 쓸 경우 해당 EIP가 현재 인스턴스에 associate되어 있는지 확인한다.
4. `ping` 대신 `ssh` 성공 여부로 최종 판단한다.

### 38. 서비스는 떠 있는데 브라우저에서 안 열리면 `127.0.0.1` bind와 Nginx/보안그룹 구조를 같이 봐야 한다

#### 증상
- `docker ps`에는 `127.0.0.1:8080`, `127.0.0.1:8081`, `127.0.0.1:3000`으로 떠 있는데 외부 브라우저에서는 안 열린다.
- EC2 안에서 `curl http://127.0.0.1:8080`은 되는데 도메인 접속은 실패한다.

#### 원인
- 단일 EC2 운영에서는 앱 포트를 외부에 직접 열지 않고 `127.0.0.1` bind 후 Nginx가 `80/443`에서 받아야 한다.
- 보안그룹이 `8080`만 열려 있고 `80/443`가 안 열려 있으면 도메인 공개가 안 된다.

#### 확인
- `docker ps`
- `curl -I http://127.0.0.1:8080`
- `sudo nginx -t`
- AWS Security Group inbound

#### 조치
1. 앱 포트는 계속 `127.0.0.1` bind로 두고, 외부 공개는 Nginx가 맡게 한다.
2. 보안그룹은 `22`, `80`, `443`만 열고 `8080` 직접 공개는 제거한다.
3. Nginx에서 `myeditor.n-e.kr -> 3000`, `editor.myeditor.n-e.kr -> 8081`, `api.myeditor.n-e.kr -> 8080`으로 reverse proxy를 잡는다.

### 39. Amazon Linux 2023에서 `docker compose`가 없으면 배포 스크립트가 바로 깨진다

#### 증상
- `./scripts/deploy-stack.sh up` 직후 `docker: 'compose' is not a docker command`가 뜬다.
- `docker --version`은 되는데 `docker compose version`이 안 된다.

#### 원인
- Docker Engine만 설치되고 Compose plugin이 빠져 있을 수 있다.
- 예전 standalone `docker-compose`와 현재 `docker compose`를 혼용하면 스크립트 기준이 어긋난다.

#### 확인
- `docker --version`
- `docker compose version`
- `which docker-compose`

#### 조치
1. 우선 `docker compose` plugin 설치를 기준으로 맞춘다.
2. 배포 스크립트는 `docker compose` 기준으로 유지하고, 필요한 경우 EC2에 Compose plugin을 수동 설치한다.
3. 단기 우회로 standalone을 쓰더라도 운영 번들 기준은 하나로 통일한다.

### 40. ECR에서 `repository not found` 또는 `manifest unknown`이 뜨면 repo, 계정 ID, 태그 placeholder를 순서대로 본다

#### 증상
- `repository ... not found`
- `.dkr.ecr.ap-northeast-2.amazonaws.com/prod-redis-service not found`
- `:replace-with-git-sha not found: manifest unknown`

#### 원인
- `<AWS_ACCOUNT_ID>`가 비어 있거나 잘못 들어간 이미지 URI
- ECR repository 자체 미생성
- `.env.backend`, `.env.frontend`에 `replace-with-git-sha` placeholder가 그대로 남아 있음
- `latest`는 기대하지만 실제 workflow는 SHA 태그만 올렸을 수 있음

#### 확인
- `aws sts get-caller-identity`
- `aws ecr describe-repositories --repository-names <repo>`
- `aws ecr list-images --repository-name <repo>`
- `/opt/deploy/.env.backend`, `/opt/deploy/.env.frontend`

#### 조치
1. 이미지 URI 앞부분의 `AWS_ACCOUNT_ID`를 실제 12자리 계정 ID로 맞춘다.
2. ECR repository가 없으면 먼저 생성한다.
3. placeholder 태그는 실제 SHA 또는 `latest`로 바꾼다.
4. `latest`를 쓸 거면 GitHub Actions가 `main/master`에서 `latest`도 push하는지 확인한다.

### 41. GitHub Actions OIDC Role은 trust policy만으로 끝나지 않고 ECR permission policy가 따로 있어야 한다

#### 증상
- GitHub Actions에서 `aws-actions/amazon-ecr-login@v2` 단계가 실패한다.
- `is not authorized to perform: ecr:GetAuthorizationToken on resource: *`가 찍힌다.

#### 원인
- IAM Role trust policy로 GitHub OIDC를 허용했더라도, 실제 ECR 권한 policy가 없으면 Assume 후 아무 작업도 못 한다.

#### 확인
- IAM Role의 `Trust policy`
- IAM Role의 `Permissions` / `Inline policy`
- GitHub Actions 에러 로그

#### 조치
1. trust policy는 GitHub repo/sub 제한용으로 유지한다.
2. 별도로 inline policy 또는 managed policy로 최소 ECR 권한을 붙인다.
3. 최소한 `ecr:GetAuthorizationToken`, `ecr:CreateRepository`, `ecr:DescribeRepositories`, `ecr:PutImage`, `ecr:UploadLayerPart` 등 push에 필요한 권한을 포함시킨다.

### 42. GitHub Actions SSH deploy가 `ssh-add -`에서 멈추면 `DEPLOY_SSH_KEY`에 넣은 키가 passphrase 있거나 공개키일 가능성이 높다

#### 증상
- `webfactory/ssh-agent@v0.9.0` 단계에서 `Enter passphrase for (stdin):`가 뜬다.
- 또는 SSH 배포는 시작도 못 하고 key parse 오류가 난다.

#### 원인
- `DEPLOY_SSH_KEY`에 passphrase 있는 개인키를 넣었거나, 아예 공개키를 넣었을 수 있다.
- CI에서는 비대화형이라 passphrase 입력이 불가능하다.

#### 확인
- GitHub secret `DEPLOY_SSH_KEY`
- 로컬 키 파일 내용이 `-----BEGIN OPENSSH PRIVATE KEY-----`로 시작하는지
- EC2 `~/.ssh/authorized_keys`

#### 조치
1. CI 전용으로 passphrase 없는 개인키를 새로 만든다.
2. GitHub secret `DEPLOY_SSH_KEY`에는 개인키 전체 본문을 넣는다.
3. EC2 `~/.ssh/authorized_keys`에는 대응하는 공개키를 새 줄로 추가한다.
4. 로컬에서 새 개인키로 `ssh -i <key> ec2-user@<host>`가 되는지 먼저 확인한다.

### 43. GitHub Actions SSH deploy는 `22/tcp -> My IP` 상태에선 실패할 수 있다

#### 증상
- `ssh-keyscan` 또는 `Deploy to EC2` 단계가 바로 실패한다.
- 로컬에서는 SSH가 되는데 GitHub Actions만 EC2에 못 붙는다.

#### 원인
- 보안그룹의 `22/tcp`를 내 공인 IP로만 제한해 두면 GitHub Actions runner IP는 막힌다.
- 자동배포를 SSH로 구현한 상태에선 runner가 직접 EC2에 들어와야 한다.

#### 확인
- GitHub Actions 로그의 `ssh-keyscan` / `ssh` 단계
- AWS Security Group inbound rule

#### 조치
1. 자동배포를 유지할 거면 일시적으로 `22/tcp`를 외부에서 접근 가능하게 두거나, GitHub runner IP 허용 구조를 따로 만든다.
2. 더 안전하게 가려면 SSH 대신 SSM/CodeDeploy로 바꾼다.
3. 자동배포 검증이 끝나면 `22`는 다시 최소 범위로 줄인다.

### 44. `contract-service`에서 deploy bundle을 한 번 복사한 뒤엔 repo 수정이 EC2 `/opt/deploy`에 자동 반영되지 않는다

#### 증상
- `contract-service`에는 분명 fix가 push됐는데 EC2는 여전히 이전 compose/init.sql/env 예시로 동작한다.
- 같은 장애를 고쳤는데 EC2 재배포 후 또 재현된다.

#### 원인
- `/opt/deploy`는 bootstrap 시점의 복사본이라 원격 Git working tree가 아니다.
- repo를 고쳐도 EC2 파일을 다시 덮지 않으면 live bundle은 그대로 남아 있다.

#### 확인
- `git log`의 최신 커밋
- EC2 `/opt/deploy/*` 파일 내용
- `contract-service/templates/single-ec2/deploy-bundle/*` 원본 내용

#### 조치
1. fix 후에는 필요한 파일을 EC2 `/opt/deploy`로 다시 복사한다.
2. 예시는 `docker-compose.backend.yml`, `scripts/deploy-stack.sh`, `config/auth-mysql/init.sql`처럼 실제 장애 지점 파일만 덮어써도 된다.
3. 복사 뒤 관련 서비스만 재기동해서 검증한다.

### 45. `auth-mysql`이 unhealthy면 init SQL이 MySQL 8 컨테이너에서 허용되지 않는 global 변수 설정을 건드리는지 본다

#### 증상
- `single-ec2-backend-auth-mysql-1`가 unhealthy로 떠서 전체 stack deploy가 멈춘다.
- 로그에 `/docker-entrypoint-initdb.d/init.sql` 실행 중 에러가 찍힌다.

#### 원인
- init SQL에서 `SET GLOBAL slow_query_log_file = '/var/log/mysql/slow.log'` 같은 값을 넣으면 MySQL 8 컨테이너 환경에서 거부될 수 있다.
- DB는 어느 정도 올라오지만 init 단계에서 실패해 health/재기동 흐름을 망친다.

#### 확인
- `docker logs single-ec2-backend-auth-mysql-1`
- `/opt/deploy/config/auth-mysql/init.sql`

#### 조치
1. 컨테이너 환경에서 허용되지 않는 `SET GLOBAL ... slow_query_log_file` 같은 줄을 제거하거나 다른 방식으로 옮긴다.
2. 수정 후 auth-mysql만 다시 올려 health를 확인한다.
3. 동일 fix를 deploy bundle 원본에도 반영한다.

### 46. `main`으로 push했는데도 `dev-*` 이미지가 만들어지면 CD의 deploy environment 결정 규칙부터 본다

#### 증상
- `main` push 후에도 `prod-*`가 아니라 `dev-*` ECR repo로 이미지가 올라간다.
- `/opt/deploy`는 `prod-*` 이미지를 참조하고 있는데 workflow는 `dev-*` 이미지를 만들고 있어 pull이 깨진다.

#### 원인
- CD workflow가 `main/master -> prod`, `dev -> dev`, `tag -> prod` 규칙으로 정리되지 않았거나, 기존 기본값이 `dev`로 남아 있을 수 있다.

#### 확인
- 각 서비스 `.github/workflows/cd.yml`
- workflow의 `deploy-gate` / target environment 계산 단계
- ECR에 실제 올라간 repository/tag

#### 조치
1. `main/master`는 `prod`, `dev` branch는 `dev`, `tag`는 `prod`로 분기 규칙을 고정한다.
2. `prod` bundle이 참조하는 repo 이름과 workflow가 push하는 repo prefix를 맞춘다.
3. 잘못 올라간 이미지 때문에 생긴 runtime mismatch는 새 `prod` 이미지 배포 후 다시 확인한다.
