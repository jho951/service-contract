# Editor V2 Extension

이 문서는 `Document`, `Block`, 추후 `Workspace`까지도 하나의 공통 operation core로 묶고, 영속 모델은 분리 유지하는 4번 방안을 정리한다.

## 목적
- 편집 경험을 하나의 operation 흐름으로 통일한다.
- 저장 구조는 도메인별로 유지한다.
- 공통 정책은 공유하고, 도메인 invariant는 분리한다.
- 향후 `Workspace`가 추가되더라도 operation 계층을 재사용할 수 있게 한다.

## 범위
- move
- transaction/save
- reorder / rebalance
- batch apply 성격 작업
- 공통 sortKey policy
- 공통 tracing / logging / validation entry

## 비범위
- `Document`, `Block`, `Workspace`의 영속 엔티티 통합
- `Node` 단일 테이블 도입
- CRUD 전체의 단일 컨트롤러 통합
- type별 권한/소유권/콘텐츠 규칙 통합

## 권장 구조
- `DocumentController`
- 블록 전용 CRUD 컨트롤러
- `Workspace`가 활성화되면 별도 CRUD 컨트롤러
- `EditorOperationController`
- `EditorOperationService`
- 타입별 domain service
- 기존 transaction orchestrator
- 공통 sortKey generator

## 4번 방안의 핵심
1. 리소스 CRUD는 각 도메인별 컨트롤러와 서비스에 남긴다.
2. 공통 편집 행위는 `EditorOperationController` 아래로 모은다.
3. 공통 작업은 command와 orchestration에서 먼저 정리한다.
4. 저장 모델은 도메인별로 유지하고, 공통 정책만 공유한다.

## 공통화 기준
- 정적 리소스 상태를 바꾸는 요청이면 리소스 컨트롤러로 둔다.
- editor 상호작용에서 생기는 작업이면 operation 컨트롤러로 보낸다.
- 공통화는 request shape, command, tracing, logging, testing에서 먼저 얻는다.
- 공통 policy는 `sortKey`, move anchor, batch apply 순서, operation status에 둔다.

## 주요 흐름
### move
1. 프론트는 공통 move 요청을 보낸다.
2. `EditorOperationController`가 공통 request를 받는다.
3. command로 변환한다.
4. `EditorOperationService`가 타입별 service로 분배한다.
5. 실제 검증과 영속 변경은 각 도메인 서비스가 담당한다.
6. 공통 sortKey 정책은 shared policy layer에서 재사용한다.

### transaction/save
1. 프론트는 editor operation batch를 보낸다.
2. `EditorOperationController`가 공통 입구에서 받는다.
3. 기존 transaction orchestrator를 호출한다.
4. 필요하면 기존 `DocumentTransactionServiceImpl`, `DocumentTransactionOperationExecutor` 구조를 operation 관점에서 재배치한다.
5. batch apply 결과와 versioning은 공통 response shape로 맞춘다.

## 레이어
### Resource layer
- `Document`
- `Block`
- `Workspace` backup 또는 future activation

### Operation layer
- move
- reorder
- transaction/save
- batch apply

### Domain layer
- `Document` lifecycle
- `Block` content and tree rules
- `Workspace` ownership and container rules

### Shared policy layer
- `sortKey` policy
- trace id / request id propagation
- operation validation envelope
- batch ordering semantics

## 기대 효과
- 공통 흐름을 서비스 입구에서 통합할 수 있다.
- 저장 모델 변경 없이 공통 작업 의미를 공유할 수 있다.
- type별 정책과 lifecycle을 흐리지 않는다.
- 현재 v1 계약과의 충돌을 줄인다.
- 나중에 `Workspace`가 추가되어도 operation 축은 유지된다.

## 유지 원칙
1. v1 CRUD는 현재 리소스 경계를 유지한다.
2. operation 공통화는 editor interaction에만 적용한다.
3. `Node`는 별도 미래 연구 축으로 남기고, v2의 기본 전제로 두지 않는다.
4. 공통화 이득이 storage 복잡도를 앞서지 않는 한 persistence는 분리한다.
