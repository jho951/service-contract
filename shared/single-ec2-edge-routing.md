# Single EC2 Edge Routing Contract

이 문서는 단일 EC2에서 백엔드 7개 서비스와 프론트 2개 페이지를 함께 운영할 때의 외부 진입 구조를 정의한다.

대상:

- `gateway-service`
- `auth-service`
- `user-service`
- `authz-service`
- `editor-service`
- `redis-service`
- `monitoring-service`
- `editor-page`
- `explain-page`

기본 선언:

```text
등록 도메인은 하나만 사용하고, 외부 공개는 Nginx가 담당하며, 애플리케이션은 127.0.0.1 bind 또는 Docker 내부 network로만 노출한다.
```

## 1. 등록 도메인 1개 기준 구조

권장 기준:

- 등록 도메인: `myeditor.n-e.kr` 한 개
- 공개 엔드포인트는 같은 등록 도메인 아래 서브도메인으로 분리
- 즉 `api.myeditor.n-e.kr`, `editor.myeditor.n-e.kr`, `myeditor.n-e.kr`은 추가 도메인 구매가 아니라 같은 등록 도메인 활용이다

| 용도 | 도메인 예시 | upstream |
| --- | --- | --- |
| Public API | `api.myeditor.n-e.kr` | `gateway-service` |
| Editor UI | `editor.myeditor.n-e.kr` | `editor-page` |
| Explain UI | `myeditor.n-e.kr` | `explain-page` |
| Grafana | `grafana.myeditor.n-e.kr` | `monitoring-service` grafana |

운영 원칙:

- `api.myeditor.n-e.kr`만 백엔드 진입점으로 본다.
- `editor-page`, `explain-page`는 gateway public URL을 사용한다.
- Grafana는 가능하면 public 공개 대신 운영자 IP 제한 또는 VPN 뒤에 둔다.
- 이 문서의 `editor.myeditor.n-e.kr`, `api.myeditor.n-e.kr`, `grafana.myeditor.n-e.kr`, `myeditor.n-e.kr`은 모두 등록 도메인 `myeditor.n-e.kr` 하나 기준의 공개 엔드포인트다.
- path 기반 단일 host 라우팅(`/editor`, `/explain`)도 가능하지만, 현재 프론트 빌드 기준에서는 서브도메인 분리가 추가 수정이 적다.

## 2. 최종 포트 정책

| 런타임 | 컨테이너 포트 | host bind 권장값 | 외부 직접 공개 | 비고 |
| --- | --- | --- | --- | --- |
| `gateway-service` | `8080` | `127.0.0.1:8080` | 아니오 | Nginx가 `api.myeditor.n-e.kr`으로 프록시 |
| `editor-page` | `80` | `127.0.0.1:8081` | 아니오 | Nginx가 `editor.myeditor.n-e.kr`으로 프록시 |
| `explain-page` | `3000` | `127.0.0.1:3000` | 아니오 | Nginx가 `myeditor.n-e.kr`으로 프록시 |
| `grafana` | `3000` | `127.0.0.1:3005` | 기본 아니오 | 필요 시 IP 제한 공개 |
| `auth-service` | `8081` | 미사용 | 아니오 | Docker network alias만 사용 |
| `user-service` | `8082` | 미사용 | 아니오 | Docker network alias만 사용 |
| `editor-service` | `8083` | 미사용 | 아니오 | Docker network alias만 사용 |
| `authz-service` | `8084` | 미사용 | 아니오 | Docker network alias만 사용 |
| `redis-service` | `6379` | 미사용 | 아니오 | host publish 금지 |
| `prometheus` | `9090` | 기본 미사용 | 아니오 | 운영자만 필요 시 제한 공개 |
| `loki` | `3100` | 미사용 | 아니오 | 내부 수집용 |

핵심:

- 외부 inbound는 `22`, `80`, `443`만 연다.
- `8080`, `8081`, `3000`, `3005`도 가능하면 `127.0.0.1` bind로 유지한다.
- Redis와 내부 앱 서비스는 host publish를 하지 않는다.

## 3. 프론트 env 기준

### editor-page

```env
EDITOR_PAGE_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-editor-page:<sha>
EDITOR_PAGE_PROD_PORT=8081
VITE_GATEWAY_BASE_URL=https://api.myeditor.n-e.kr
VITE_API_BASE_URL=https://api.myeditor.n-e.kr
VITE_DOCUMENTS_API_BASE_URL=https://api.myeditor.n-e.kr
VITE_START_FRONTEND_URL=https://myeditor.n-e.kr
VITE_SITE_URL=https://editor.myeditor.n-e.kr
VITE_POST_AUTH_REDIRECT_URL=https://editor.myeditor.n-e.kr
```

### explain-page

```env
EXPLAIN_PAGE_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/prod-explain-page:<sha>
EXPLAIN_PAGE_PROD_PORT=3000
NEXT_PUBLIC_GATEWAY_BASE_URL=https://api.myeditor.n-e.kr
NEXT_PUBLIC_SSO_BASE_URL=https://api.myeditor.n-e.kr
NEXT_PUBLIC_GATEWAY_AUTH_LOGIN_PAGE=explain
NEXT_PUBLIC_START_FRONTEND_URL=https://editor.myeditor.n-e.kr
NEXT_PUBLIC_SSO_CONSUMER_CALLBACK_URL=https://editor.myeditor.n-e.kr/auth/callback
```

## 4. Nginx 기준

권장 구조:

```text
Internet
  -> 80/443
  -> Nginx on EC2
  -> 127.0.0.1:8080 gateway-service
  -> 127.0.0.1:8081 editor-page
  -> 127.0.0.1:3000 explain-page
```

예시 설정:

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name api.myeditor.n-e.kr;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}

server {
    listen 80;
    server_name editor.myeditor.n-e.kr;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name myeditor.n-e.kr;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
```

비고:

- TLS를 붙일 경우 `listen 443 ssl;`과 인증서 경로를 추가한다.
- `api.myeditor.n-e.kr`은 cookie 기반 인증과 redirect가 있으므로 `Host`, `X-Forwarded-Proto`를 반드시 전달한다.

## 5. Security Group 기준

허용:

- `22/tcp`: 운영자 고정 IP
- `80/tcp`: 전체 공개
- `443/tcp`: TLS 사용 시 전체 공개

비권장:

- `8080/tcp`, `8081/tcp`, `3000/tcp`, `3005/tcp` 직접 공개
- `6379/tcp`, `8082/tcp`, `8083/tcp`, `8084/tcp`, `9090/tcp`, `3100/tcp` 외부 공개

## 6. 실행 순서

1. backend 7개를 기동한다.
2. `gateway-service` health를 확인한다.
3. `editor-page`, `explain-page`를 기동한다.
4. Nginx 설정을 반영한다.
5. 각 도메인에서 `200`, 로그인 redirect, callback 흐름을 확인한다.

## 7. 연관 문서

- [single-ec2-deployment.md](single-ec2-deployment.md)
- [implementation-rollup-2026-04-24.md](implementation-rollup-2026-04-24.md)
- [../templates/single-ec2/nginx.single-ec2.conf.example](../templates/single-ec2/nginx.single-ec2.conf.example)
