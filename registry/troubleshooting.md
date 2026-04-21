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
- `AUTH_SERVICE_URL`, `AUTHZ_SERVICE_URL`, `USER_SERVICE_URL`, `BLOCK_SERVICE_URL` 중 하나가 잘못됨
- shared network alias가 누락됨
- upstream 서비스가 다른 브랜치/포트로 떠 있음

##### 확인
- `repositories/gateway-service/execution.md`
- `repositories/gateway-service/env.md`
- `./scripts/msa-stack.sh up`

##### 조치
1. `./scripts/msa-stack.sh ps`로 컨테이너 이름과 포트를 본다.
2. current 배포가 dev면 `authz-service`, prod면 `permission-service`로 떠 있는지 확인한다.
3. Gateway 환경변수가 실제 authz host를 바라보는지 확인한다.
4. editor/document upstream은 current 구현 기준 `documents-service:8083`인지 확인한다.

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
- 프록시/로드밸런서가 `OPTIONS`를 가로챔

##### 확인
- `repositories/gateway-service/auth-proxy.md`
- `shared/security.md`

##### 조치
1. `Origin`과 CORS 설정을 비교한다.
2. `OPTIONS`가 Gateway까지 도달하는지 확인한다.
3. 응답의 `Access-Control-Allow-*` 헤더를 점검한다.

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
- DB 일부 마이그레이션 누락
- 캐시 초기화 실패

##### 확인
- `repositories/authz-service/ops.md`
- `repositories/redis-service/ops.md`

##### 조치
1. DB와 Redis 연결을 분리해서 본다.
2. 캐시 없이 DB fallback이 되는지 확인한다.
3. readiness가 `DOWN`인 이유를 로그에서 찾는다.

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
1. `gateway:session:`과 `gateway:admin-permission:` prefix를 확인한다.
2. TTL이 문서와 맞는지 본다.
3. key collision 여부를 확인한다.

#### 2. Redis 인증 실패 / 연결 실패
##### 증상
- 서비스가 Redis에 붙지 못한다.
- readiness가 DOWN이다.

##### 원인
- 비밀번호 불일치
- host/port 오타
- Redis가 `redis-server` / `central-redis`가 아닌 다른 이름으로 떠 있거나 shared network가 맞지 않음

##### 확인
- `repositories/redis-service/ops.md`
- `shared/env.md`

##### 조치
1. `redis-cli PING`으로 직접 확인한다.
2. Gateway/Authz/terraform 예시는 `central-redis`, Redis repo service key는 `redis-server`를 쓰는지 확인한다.
3. Redis 예제 env의 `backend-shared`와 실제 shared network 이름이 같은지 확인한다.

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
#### 1. README는 main인데 실제 블록 연동은 dev로 안 맞음
##### 증상
- 문서에 적힌 브랜치와 실제 실행 브랜치가 다르다.
- `editor-service` 동기화가 안 된 것처럼 보인다.

##### 원인
- 이 레포는 `editor-service`를 `dev` 기준으로 오케스트레이션한다.

##### 확인
- `registry/deployment-topology.md`
- `scripts/msa-stack.sh`

##### 조치
1. Block 레포가 dev 브랜치인지 확인한다.
2. docs와 스크립트의 기준을 일치시킨다.

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
- editor-service dev 브랜치와 editor 문서가 불일치
- block API와 editor API가 서로 다른 contract를 참조

##### 확인
- `registry/deployment-topology.md`
- `repositories/editor-service/README.md`
- `repositories/editor-service/api.md`

##### 조치
1. Block 서버 브랜치와 실행 스크립트를 맞춘다.
2. editor가 참조하는 block contract 버전을 확인한다.

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
- Redis host가 `central-redis`가 아닌 다른 이름으로 남아 있다.
- local `USER_SERVICE_BASE_URL`이 실제 user-service 포트 `8082`와 다르다.

#### 확인
- `repositories/auth-service/README.md`
- `repositories/user-service/README.md`

#### 조치
1. auth-service 예시 Redis host는 `central-redis`로 유지한다.
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

### 5. Gateway platform-security 모듈 버전은 같은 minor로 맞춘다
#### 증상
- 빌드는 되거나 안 되거나 환경마다 달라지고, runtime linkage 문제가 날 수 있다.

#### 원인
- `platform-security-bom` 버전과 직접 pin한 `platform-security-core` 버전이 다르다.

#### 확인
- `repositories/gateway-service/README.md`
- `repositories/gateway-service/security.md`

#### 조치
1. `platform-security-core`는 BOM과 같은 minor 버전으로 맞춘다.
2. 개별 모듈을 직접 pin할 때는 starter/core/web/bridge family를 같이 검토한다.

### 6. authz-service dev compose에 Redis가 내장돼 있으면 branch drift를 의심한다
#### 증상
- authz dev stack과 redis-service dev stack을 같이 올릴 때 `6379` 충돌 또는 `central-redis` alias 충돌이 난다.

#### 원인
- 최신 main이 아니라 과거 branch에서 authz-service dev compose가 Redis를 함께 띄우는 경우가 있다.

#### 확인
- `repositories/authz-service/ops.md`
- `repositories/redis-service/README.md`

#### 조치
1. 최신 기준 authz-service dev compose에는 Redis가 없어야 한다.
2. 공용 Redis는 `redis-service`의 `central-redis` 하나만 사용한다.
