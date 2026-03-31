# Gateway Documentation

`Gateway` 서비스 계약 허브다.

## 문서
- [책임과 경계](responsibility.md)
- [인증 프록시](auth-proxy.md)
- [헤더 계약](headers.md)
- [인증 계약](auth.md)
- [보안 계약](security.md)
- [캐시 계약](cache.md)
- [응답 계약](response.md)
- [실행 문서](execution.md)
- [환경변수 계약](env.md)
- [에러 계약](errors.md)
- [인증 흐름](auth-flow.md)

## 읽는 순서
1. `responsibility.md`로 Gateway가 맡는 역할을 먼저 본다.
2. `auth-proxy.md`와 `auth.md`로 인증 흐름과 채널 선택을 본다.
3. `headers.md`와 `security.md`로 신뢰 경계를 확인한다.
4. `cache.md`로 L1/L2 캐시와 rate limit을 확인한다.
5. `response.md`, `execution.md`, `env.md`, `errors.md`로 운영 계약을 본다.

## 참고
- 이 허브는 기존 상세 문서들의 진입점이다.
- 구현 세부는 현재 코드 기준으로 유지하고, 변경 시 이 허브 아래 문서를 먼저 갱신한다.
