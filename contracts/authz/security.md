# Authz Security Contract

## Trust Boundary
- 외부 클라이언트는 Gateway를 통해 관리자 경로에 접근하는 것을 기본으로 한다.
- 내부 판정 API는 Gateway 또는 신뢰 가능한 내부 네트워크에서만 사용한다.
- 외부에서 주입된 `X-User-Id`, `X-User-Role`, `X-Session-Id`, `X-Original-Method`, `X-Original-Path`는 Gateway 재주입 규칙 없이 직접 신뢰하지 않는다.

## Authorization Policy
- 관리자 경로 이외의 요청은 기본적으로 거부한다.
- HTTP method에 따라 `ADMIN_READ`, `ADMIN_WRITE`, `ADMIN_DELETE`, `ADMIN_MANAGE`를 매핑한다.
- `/admin/manage/**`와 `/v1/admin/manage/**`는 `ADMIN_MANAGE`를 요구한다.
- 허용 실패는 거부 사유를 남기되, 정책 원문은 외부에 노출하지 않는다.

## Trusted Context
- Gateway가 재주입한 `X-Request-Id`, `X-Correlation-Id`만 추적 기준으로 사용한다.
- `X-User-Role`은 참고값이며, 최종 판정은 RBAC 매핑과 path/method 규칙으로 한다.
- `X-Session-Id`는 사용자 세션 식별 보조값이며, 감사와 중복 판정에 사용한다.

## Audit and Policy
- 정책 변경과 권한 거부 이벤트는 감사 로그에 남겨야 한다.
- 관리자 권한 부여/회수는 별도 운영 기록으로 남긴다.
