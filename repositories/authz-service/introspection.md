# Authz Introspection Contract

이 문서는 어떤 요청을 로컬 JWT만으로 처리할지, 어떤 요청을 현재 권한 상태까지 확인할지 정의한다.

## 분류
| Risk | Examples | Strategy |
| --- | --- | --- |
| Low | page list, public read, profile view | Gateway JWT check + short cache |
| Medium | comment create, page update, block move | JWT + authz cache |
| High | share, role grant/revoke, visibility change, delete/restore, admin access | real-time authz evaluation |

## 원칙
- 고위험 API는 로컬 JWT만으로 허용하지 않는다.
- introspection은 토큰 유효성뿐 아니라 현재 권한 유효성도 검사한다.
- 결과는 cacheable 하되, version mismatch 시 즉시 폐기한다.

## 적합한 시점
- 로그인 직후 권한 스냅샷 확인
- refresh 시 권한 상태 재검증
- 권한 변경 직후 세션 재평가
- 고위험 API 호출 직전
