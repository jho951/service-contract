# Troubleshooting

이 문서는 실제 장애 통계 보고서가 아니라, 현재 contract와 아키텍처 문서에서 식별한 실패 모드와 설계 대응을 정리한 공통 가이드다.
실측 에러율, 지연 시간, 장애 건수처럼 운영 수치가 없는 항목은 과장하지 않고 정성 표현만 사용한다.
실제 수치는 각 서비스 구현 레포의 모니터링, runbook, postmortem에서 확인된 경우에만 별도로 추가한다.

## Problem 1. `/health`는 통과하지만 실제 요청은 실패한다

### Cause
- 프로세스 생존 확인과 실제 요청 처리 준비 상태를 같은 신호로 취급하면, 애플리케이션은 떠 있어도 DB, Redis, 필수 downstream이 아직 준비되지 않은 상태를 놓칠 수 있다.
- 배포나 재기동 직후 `/health`만 보고 트래픽을 붙이면 일부 요청이 실패하거나 지연될 수 있다.

### Solution
- `/health`는 프로세스와 애플리케이션 생존 확인으로 제한하고, `/ready`는 DB, Redis, 필수 downstream 준비 상태를 반영하도록 분리한다.
- 배포 게이트와 smoke check는 `/health`만 보지 않고 `/ready`와 대표 API route를 함께 확인한다.
- health/readiness path나 의미를 바꾸면 monitoring, deploy, Terraform 기준도 함께 갱신한다.

## Problem 2. 로그인은 보이지만 세션이 유지되지 않거나 브라우저가 로그인 루프에 들어간다

### Cause
- 브라우저가 backend 개별 서비스를 직접 호출하거나, Gateway 기준이 아닌 base URL을 사용하면 cookie 경계와 인증 흐름이 흔들릴 수 있다.
- reverse proxy가 `Host`, `X-Forwarded-Proto`를 제대로 전달하지 않으면 redirect URI, cookie domain, secure 판정이 어긋날 수 있다.
- `/v1` prefix를 중복 조립하거나 빠뜨리면 로그인 이후 후속 호출만 실패하는 드리프트가 생길 수 있다.

### Solution
- 브라우저 클라이언트는 backend 개별 서비스가 아니라 Gateway public route만 직접 호출하도록 유지한다.
- Nginx나 edge proxy는 `Host`, `X-Forwarded-Proto`를 포함한 기본 전달 헤더를 유지한다.
- frontend base URL, auth callback, cookie domain/path/SameSite 기준을 Gateway public contract에 맞춰 한 번에 정렬한다.

## Problem 3. 문서와 런타임이 어긋나서 404, 405, 422 같은 계약 불일치가 생긴다

### Cause
- contract 문서가 먼저 바뀌고 구현 레포의 route, DTO, OpenAPI, Gateway 매핑이 동시에 갱신되지 않으면 문서와 런타임이 다른 상태가 된다.
- `contract.lock.yml`이 없거나 오래된 경우, 어떤 contract snapshot을 구현이 기준으로 삼았는지 추적하기 어렵다.
- frontend처럼 partial adoption 상태인 소비자는 공통 거버넌스가 약해져 드리프트가 더 늦게 드러날 수 있다.

### Solution
- contract를 소비하는 서비스 레포는 `contract.lock.yml`에 ref, commit, consumes를 고정한다.
- CI의 첫 단계에서 `contract-lock` 검증을 수행해 계약과 구현의 불일치를 일찍 드러내도록 한다.
- public route 변경은 Gateway route table, 서비스 구현, OpenAPI artifact를 같은 변경 흐름에서 함께 갱신한다.

## Problem 4. 관리자 경로나 내부 위임 호출이 예상과 다르게 403 또는 5xx를 반환한다

### Cause
- Gateway가 `X-User-Id`, `X-Original-Method`, `X-Original-Path` 같은 내부 판정 문맥을 누락하거나 다른 값으로 전달하면 `authz-service` 판정이 실패할 수 있다.
- 내부 verify path와 실제 upstream endpoint가 어긋나면 관리자 경로 전체가 실패할 수 있다.
- Authz의 DB 또는 Redis 준비가 끝나기 전에 판정 요청이 들어오면 일부 경로만 먼저 실패할 수 있다.

### Solution
- 관리자 판정에 필요한 내부 헤더와 verify endpoint를 contract 수준에서 고정하고, Gateway와 Authz가 같은 기준을 보도록 유지한다.
- 권한 데이터 자체를 의심하기 전에 internal auth 문맥, trace header, verify path 드리프트를 먼저 확인한다.
- Authz readiness는 캐시와 DB 준비 상태를 반영하도록 유지하고, 관리자 경로 smoke check를 별도로 둔다.

## Problem 5. 내부 서비스나 운영 도구가 의도치 않게 public surface가 된다

### Cause
- 단일 EC2나 reverse proxy 구성에서 Gateway 외 포트를 직접 공개하면 backend와 operator surface가 외부에 드러날 수 있다.
- Grafana, Prometheus, Loki 같은 운영 도구를 product public endpoint와 같은 방식으로 노출하면 보안 경계가 흐려진다.
- 서비스가 `127.0.0.1` bind 대신 외부 인터페이스로 열리면 Nginx를 우회하는 접근면이 생길 수 있다.

### Solution
- 외부 공개 backend 진입점은 Gateway 하나로 두고, 다른 서비스는 Docker 내부 network 또는 `127.0.0.1` bind를 기본값으로 유지한다.
- Grafana 같은 observability UI는 operator/private access를 기본으로 두고, 예외 공개가 필요하면 IP 제한이나 VPN 같은 추가 제어를 같이 둔다.
- 공개 포트, Nginx upstream, service bind 주소는 배포 번들과 contract 문서에서 함께 관리한다.

## Problem 6. 장애가 나도 어느 계층이 먼저 실패했는지 빠르게 구분되지 않는다

### Cause
- Gateway 에러와 upstream 에러가 서로 다른 모양으로 노출되면, 같은 증상처럼 보여도 원인 계층을 바로 나누기 어렵다.
- health, readiness, log, metric 기준이 서비스마다 제각각이면 같은 장애를 두고도 해석이 달라질 수 있다.
- 관측 시스템을 operator surface가 아니라 일반 product surface처럼 다루면, 운영 정보는 늘어도 원인 분류는 오히려 흐려질 수 있다.

### Solution
- Gateway 자체 에러와 upstream 에러는 공통 error envelope shape를 유지해 원인 추적 단서를 공통화한다.
- edge에서는 error rate, latency, upstream timeout 증가 여부를 보고, 각 서비스에서는 readiness와 dependency 상태를 함께 본다.
- 관측 시스템은 operator surface로 유지하고, 실제 수치가 확인된 뒤에만 서비스별 runbook이나 postmortem에 정량 값을 추가한다.

## 연관 문서

- [../adr/0002-gateway-owns-public-edge.md](../adr/0002-gateway-owns-public-edge.md)
- [../adr/0006-contract-lock-and-ci-governance.md](../adr/0006-contract-lock-and-ci-governance.md)
- [../adr/0011-observability-is-an-operator-surface.md](../adr/0011-observability-is-an-operator-surface.md)
- [../adr/0015-health-and-readiness-are-distinct-contracts.md](../adr/0015-health-and-readiness-are-distinct-contracts.md)
- [../conventions/api-standard.md](../conventions/api-standard.md)
- [../conventions/shared/single-ec2-edge-routing.md](../conventions/shared/single-ec2-edge-routing.md)
- [../conventions/versioning/contract-versioning.md](../conventions/versioning/contract-versioning.md)
- [../services/registry/troubleshooting.md](../services/registry/troubleshooting.md)
