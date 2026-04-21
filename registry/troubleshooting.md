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
- Gateway local은 auth-service를 `localhost:8081`로 기대하는데 실제 auth-service local은 `8082`에서 뜬다.
- auth-service local과 user-service local을 동시에 띄우면 둘 다 `8082`를 쓰려 해서 포트 충돌이 난다.

##### 원인
- `gateway-service/.env.local`은 `AUTH_SERVICE_URL=http://localhost:8081`를 사용한다.
- `auth-service/.env.local`은 현재 `SERVER_PORT=8082`다.
- `user-service/app/src/main/resources/application-dev.yml`의 기본 포트도 `8082`다.
- 참고로 Gateway local에는 예전처럼 별도 `AUTH_VALIDATE_URL`이 있지 않고, validate 호출도 `AUTH_SERVICE_URL` 기준으로 파생된다.

##### 확인
- `repositories/gateway-service/env.md`
- `repositories/auth-service/README.md`
- `repositories/user-service/README.md`

##### 조치
1. host local 기준을 유지하려면 auth-service local 포트를 `8081`로 맞추는 편이 자연스럽다.
2. 반대로 auth-service local을 `8082`로 유지할 거면 Gateway local `AUTH_SERVICE_URL`도 같이 바꿔야 한다.
3. auth-service와 user-service를 동시에 host bootRun 할 때는 `8082` 중복 여부를 먼저 본다.

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

#### 5. auth-service local의 `SSO_GITHUB_CALLBACK_URI=http://localhost:8082/login/oauth2/code/github`는 현재 즉시 장애라기보다 혼란을 만드는 drift다
##### 증상
- local SSO를 볼 때 어떤 문서는 Gateway callback을 말하고, 어떤 env는 auth-service 직결 callback을 말해 혼란이 생긴다.
- `redirect_uri` mismatch를 디버깅할 때 실제 활성 경로와 env 값이 달라 보인다.

##### 원인
- 현재 auth-service dev Spring OAuth2 설정은 `redirect-uri: "{baseUrl}/v1/login/oauth2/code/{registrationId}"`를 사용한다.
- 프런트도 `GET /v1/auth/sso/start`처럼 Gateway 공개 경로를 기준으로 로그인 시작을 만든다.
- 반면 `auth-service/.env.local`의 `SSO_GITHUB_CALLBACK_URI=http://localhost:8082/login/oauth2/code/github`는 Gateway ingress 모델과 맞지 않는다.
- 추가로 현재 코드 기준 `SSO_GITHUB_CALLBACK_URI`는 `sso.github.callback-uri`로 로드되지만, active Spring OAuth2 login redirect 계산에는 직접 쓰이지 않는다.

##### 확인
- `auth-service/.env.local`
- `auth-service/app/src/main/resources/dev/application-dev_auth.yml`
- `auth-service/app/src/main/resources/dev/application-dev_sso.yml`
- `repositories/auth-service/README.md`
- `repositories/gateway-service/auth-flow.md`

##### 조치
1. 이것은 현재 즉시 부팅 장애는 아니다.
2. 다만 현재 MSA ingress 계약이 Gateway-first라면 local 문서와 예시도 `http://localhost:8080/v1/login/oauth2/code/github` 또는 `http://127.0.0.1:8080/v1/login/oauth2/code/github` 기준으로 맞추는 편이 덜 헷갈린다.
3. auth-service 직결 모델을 유지할 거면, 그 경로가 “standalone auth-service debug 전용”이라는 점을 문서에 분리해 적는다.

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

#### 확인
- `repositories/gateway-service/auth.md`
- `repositories/gateway-service/auth-flow.md`
- `shared/security.md`

#### 조치
1. 브라우저 origin과 Gateway CORS 허용 origin을 정확히 맞춘다.
2. `OPTIONS` 응답에 `Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials`, `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers`가 모두 있는지 본다.
3. 로컬 기준 origin이 `http://127.0.0.1:3000`이면 Gateway도 그 값을 명시적으로 허용해야 한다.

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
