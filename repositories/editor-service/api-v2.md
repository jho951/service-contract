# Future Node API Contract v2

future Node v2 API는 `Node` 중심 리소스를 기준으로 정의한다.

## 리소스
- `Node`
- `BlockContent`
- `PageMeta`
- `WorkspaceMeta`
- `NodeReference`

## 권장 API 형태

### Node
- `GET /v2/editor/nodes/{nodeId}`
- `GET /v2/editor/nodes/{nodeId}/children`
- `POST /v2/editor/nodes`
- `PATCH /v2/editor/nodes/{nodeId}`
- `DELETE /v2/editor/nodes/{nodeId}`
- `POST /v2/editor/nodes/{nodeId}/move`

### BlockContent
- `GET /v2/editor/nodes/{nodeId}/content`
- `PUT /v2/editor/nodes/{nodeId}/content`

### PageMeta
- `GET /v2/editor/pages/{nodeId}/meta`
- `PUT /v2/editor/pages/{nodeId}/meta`

### WorkspaceMeta
- `GET /v2/editor/workspaces/{nodeId}/meta`
- `PUT /v2/editor/workspaces/{nodeId}/meta`

### NodeReference
- `GET /v2/editor/nodes/{nodeId}/references`
- `POST /v2/editor/nodes/{nodeId}/references`
- `DELETE /v2/editor/nodes/{nodeId}/references/{referenceId}`

## 공통 규칙
1. `Node.type`은 요청/응답에서 항상 명시한다.
2. `parentId`와 `order`는 트리 정렬과 이동의 기준이다.
3. `childrenIds`는 응답 편의 필드로는 허용할 수 있지만, 저장 원본은 아니다.
4. `BlockContent.content`는 JSON 스키마 버전을 가질 수 있다.
5. `NodeReference`는 트리 관계와 분리된 별도 그래프 리소스다.

## 예시 응답
```json
{
  "id": "6d2f6c5c-57d4-4d4a-bd6e-2af9f4b98a91",
  "type": "PAGE",
  "parentId": "b34d1c3d-2f5f-4c7a-9b35-31d6e7d7d2a1",
  "order": "k00012",
  "meta": {
    "title": "Project Notes",
    "icon": "📝",
    "cover": null
  }
}
```

## 상태 코드
- `400`
  - 잘못된 `type`, `parentId`, `order`, `content` 형식
- `404`
  - 노드 또는 메타 리소스 없음
- `409`
  - 순환 참조, 정렬 충돌, 타입 불일치
- `422`
  - 비즈니스 규칙 위반
