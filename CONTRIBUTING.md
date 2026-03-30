# Contributing

## PR 규칙
1. 변경 목적을 명시 (`bugfix`, `contract-update`, `breaking-change`)
2. 영향 서비스 체크
   - gateway
   - auth
   - user
   - redis
   - block(dev)
3. 변경 유형
   - Non-breaking
   - Breaking
4. 테스트 증빙
   - 계약 테스트 결과 또는 샘플 요청/응답

## 머지 조건
- 문서 + OpenAPI + 예시가 함께 갱신되어야 함
- Breaking change는 릴리즈 노트와 마이그레이션 절차 포함 필수
