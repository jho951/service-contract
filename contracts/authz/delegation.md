# Delegation Contract

이 문서는 `Authz-server`의 권한 위임 규칙을 정의한다.

## 목표
- owner가 특정 범위의 권한을 다른 주체에게 위임할 수 있게 한다.
- 위임 범위와 만료, 재위임 가능 여부를 명시한다.
- 공유/협업 기능의 책임 경계를 정책 수준에서 고정한다.

## 위임 역할
| Role | Description |
| --- | --- |
| OWNER | 리소스의 최상위 위임 주체 |
| MANAGER | 제한된 관리 권한 위임 가능 |
| EDITOR | 편집 권한 보유 |
| REVIEWER | 코멘트/검토 권한 보유 |
| COMMENTER | 댓글 권한 보유 |
| VIEWER | 열람만 가능 |
| AUDITOR | 열람 + 감사 조회만 가능 |

## 위임 규칙
- `OWNER`는 `MANAGER`, `EDITOR`, `REVIEWER`, `COMMENTER`, `VIEWER`를 부여할 수 있다.
- `MANAGER`는 제한된 범위에서만 `EDITOR`, `REVIEWER`, `COMMENTER`, `VIEWER`를 부여할 수 있다.
- `REVIEWER`와 `COMMENTER`는 재위임하지 않는 것을 기본 원칙으로 한다.
- `AUDITOR`는 편집 계열 권한을 획득하지 않는다.
- 모든 위임은 resource scope를 가져야 한다.

## scope 예시
- `workspace-level`
- `project-level`
- `page-level`

## 추천 payload
```json
{
  "grantedRole": "REVIEWER",
  "resourceType": "project",
  "resourceId": "proj-123",
  "grantedBy": "user-1",
  "grantedTo": "user-2",
  "expiresAt": "2026-04-30T00:00:00Z",
  "canRegrant": false
}
```

## 운영 원칙
- 위임은 항상 감사 로그를 남긴다.
- 위임 취소는 grant/revoke와 동일한 무효화 규칙을 따른다.
- 위임 만료 시각이 지난 권한은 캐시에서 자동 무효화될 수 있어야 한다.
