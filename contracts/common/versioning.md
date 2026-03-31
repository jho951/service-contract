# Versioning Policy

## 규칙
- Semantic Versioning: `MAJOR.MINOR.PATCH`
- `MAJOR`: Breaking contract
- `MINOR`: Backward compatible 확장
- `PATCH`: 문서/오타/비기능 보완

## 라우트 버전
- 외부 API는 `/v1/**`
- Breaking 시 `/v2/**` 신설 후 점진 전환

## 태깅
- 계약 릴리즈 태그 예시: `contract-v1.2.0`
