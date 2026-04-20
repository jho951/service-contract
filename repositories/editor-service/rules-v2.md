# Future Node Rules v2

future Node v2는 `Node` 단일 영속 모델을 기준으로 한다.

## 트리 구조
- `Node`는 `nodes` 테이블의 `parent_id`로 계층을 만든다.
- `childrenIds`는 저장하지 않는다.
- 자식 조회는 `parent_id` 기준으로 수행한다.
- `Page`도 자식을 가질 수 있다.

## 그래프 구조
- `@page mention`
- `synced block`
- `backlink`

이런 기능은 트리만으로 표현하지 않고 `NodeReference`로 분리한다.

## 정렬
- `order`는 형제 노드 순서를 결정한다.
- 추천 방식은 `LexoRank` 또는 fractional index다.
- 삽입/이동 시 재정렬 비용을 줄이기 위해 밀도 높은 순서 키를 사용한다.

## 이동 규칙
- 노드 이동은 `parent_id`와 `order`를 함께 변경한다.
- 부모가 바뀌면 하위 트리의 상대적 순서는 유지해야 한다.
- 동일 부모 내 이동은 정렬 키만 갱신할 수 있다.

## 삭제 규칙
- `Node` 삭제 시 하위 노드와 메타 데이터의 cascade 규칙을 명확히 해야 한다.
- `NodeReference`는 대상 노드가 사라지면 dangling reference 정리 정책이 필요하다.

## Block 확장
- 새로운 Block 타입은 `nodes` 테이블 구조를 바꾸지 않고 `block_type`과 `content` JSON만 확장한다.
- 렌더러는 `block_type`별 플러그인 구조로 분리한다.

## 불변식
1. `Node.type`은 실제 저장 시점에 변경 정책이 필요하다.
2. `WORKSPACE`는 루트 컨테이너 역할을 한다.
3. `PAGE`는 페이지 트리의 내부 노드가 될 수 있다.
4. `BLOCK`은 콘텐츠 렌더링 단위다.
5. 트리 관계와 참조 관계를 섞지 않는다.
