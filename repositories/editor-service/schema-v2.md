# Future Node Schema v2

Editor 서버의 future Node v2 스키마는 `Node` 단일 영속 모델을 공통 루트로 사용한다.

## 핵심 방향
- `Workspace`, `Page`, `Block`은 별도 루트 엔티티가 아니라 `Node.type`의 차이로 본다.
- `Node`는 단일 `nodes` 테이블에 저장한다.
- 트리는 `parent_id` 기반으로 구성한다.
- 타입별 메타와 본문은 별도 테이블로 분리한다.
- 그래프성 연결은 별도 reference 테이블로 분리한다.

## Node
```text
Node {
  id: UUID
  type: enum(WORKSPACE, PAGE, BLOCK)
  parent_id: UUID | NULL
  order: string
  created_at: datetime
  updated_at: datetime
}
```

### 설명
- `type`: `WORKSPACE`, `PAGE`, `BLOCK`
- `parent_id`: 상위 Node 식별자
- `order`: 형제 정렬 키. LexoRank 또는 fractional index 계열 문자열을 권장한다.
- `created_at` / `updated_at`: 공통 감사 필드

## BlockContent
```text
BlockContent {
  node_id: UUID
  block_type: string
  content: JSON
}
```

### 설명
- `node_id`: 대상 Block Node
- `block_type`: `text`, `heading`, `image`, `code`, `toggle` 등 확장 가능한 타입
- `content`: 블록 본문과 렌더링 속성

## PageMeta
```text
PageMeta {
  node_id: UUID
  title: string
  icon: string | NULL
  cover: string | NULL
}
```

### 설명
- `node_id`: 대상 Page Node
- `title`: 페이지 제목
- `icon` / `cover`: 페이지 메타 정보

## WorkspaceMeta
```text
WorkspaceMeta {
  node_id: UUID
  name: string
  owner_id: UUID
}
```

### 설명
- `node_id`: 대상 Workspace Node
- `name`: 워크스페이스 이름
- `owner_id`: 소유자 사용자 ID

## NodeReference
```text
NodeReference {
  from_node_id: UUID
  to_node_id: UUID
  type: enum(MENTION, LINK, SYNC)
}
```

### 설명
- `from_node_id`: 참조를 시작한 Node
- `to_node_id`: 참조 대상 Node
- `type`: `MENTION`, `LINK`, `SYNC`

## 예시
```json
{
  "type": "BLOCK",
  "content": {
    "text": "hello",
    "styles": ["bold"]
  }
}
```
