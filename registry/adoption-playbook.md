# Adoption Playbook

## 1) 서비스 레포에 Contract Link 추가
- README 상단에 Contract Source 섹션 추가
- `https://github.com/jho951/service-contract` 링크 명시
- 프론트엔드 레포 예시: [README Contract Source Section](../templates/readme-contract-source-frontend.md)

## 2) contract.lock.yml 배치
- 서비스별 SoT 브랜치와 contract ref를 명시한다.
- 백엔드 서비스와 프론트엔드 소비자 모두 `contract.lock.yml`을 유지한다.
- 서비스가 소비하는 계약 문서와 OpenAPI만 `consumes`에 남긴다.
- 운영 체크리스트와 검증 결과는 수동 문서가 아니라 CI 결과로 남긴다.
- 예시 템플릿: [Contract Lock Template](../templates/contract-lock-template.yml)

## 3) 계약 변경 절차 강제
- 구현 PR 전에 contract PR 선반영
- breaking change는 버전 증가 + migration 문서 필수
- 서비스 PR은 `contract.lock.yml`이 가리키는 contract ref를 기준으로 자동 검증한다.

## 4) 정기 점검
- 분기별로 adoption-matrix 상태 갱신
- gateway와 각 서비스의 route/header/security drift 확인
