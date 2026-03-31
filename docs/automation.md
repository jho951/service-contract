# Automation

이 문서는 contract 변경과 service 동기화를 자동화하는 방법을 정리한다.

## 목표
- 서비스 PR에서 contract 영향 변경 누락을 차단한다.
- contract 머지 후 서비스 레포 동기화 PR 생성을 자동화할 수 있도록 한다.

## 자동화 레벨
### 1) Guardrail
- 서비스 레포 PR에서 `CONTRACT_SYNC.md` 누락 여부를 검사한다.
- 계약 영향이 있으면 머지 전에 실패시킨다.

### 2) Assist
- contract 레포 머지 후 서비스 레포에 동기화 PR을 자동 생성한다.
- PR 본문에 contract SHA, 영향 영역, 검증 항목을 넣는다.

### 3) Full automation
- 서비스 레포를 직접 수정하는 대신, 동기화 PR만 자동으로 생성한다.
- merge는 사람이 한다.

## 현재 제공 스크립트
- `scripts/contract-impact-check.sh`

이 스크립트는 서비스 코드 변경 파일을 보고 계약 영향 영역을 감지한다.
영향이 있으면 PR 내에서 `CONTRACT_SYNC.md` 갱신이 있었는지 검사한다.
지원 서비스:
- `gateway`
- `auth`
- `permission`
- `user`
- `redis`
- `block`

## 서비스 PR CI 예시
```yaml
name: contract-check

on:
  pull_request:

jobs:
  contract-impact:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Fetch base branch
        run: git fetch origin ${{ github.base_ref }} --depth=1

      - name: Run contract impact check
        env:
          SERVICE_NAME: gateway
        run: |
          curl -fsSL https://raw.githubusercontent.com/jho951/contract/main/scripts/contract-impact-check.sh -o /tmp/contract-impact-check.sh
          chmod +x /tmp/contract-impact-check.sh
          /tmp/contract-impact-check.sh "$SERVICE_NAME" "origin/${{ github.base_ref }}"
```

## contract 머지 후 동기화 PR
1. `contract` 레포 main 머지를 감지한다.
2. 영향을 받는 서비스 레포를 결정한다.
3. 서비스 레포 checkout 후 `CONTRACT_SYNC.md`를 갱신한다.
4. 새 브랜치로 push한다.
5. 서비스 레포에 PR을 생성한다.

## 권장 워크플로
- `contract` 레포: 문서/OpenAPI 검증
- 서비스 레포: 영향 검사 + `CONTRACT_SYNC.md` 검사
- 동기화 봇: contract SHA 반영 PR 생성

## 실패 시 의미
- 계약 영향 변경이 있는데 서비스 레포 `CONTRACT_SYNC.md`가 갱신되지 않았음을 의미한다.
- 조치:
  1. `contract` 레포 문서/OpenAPI 먼저 갱신
  2. 서비스 레포 `CONTRACT_SYNC.md`에 contract SHA 반영

## 참고
- 서비스 레포의 README에는 `CONTRACT_SYNC.md`를 기준 파일로 명시한다.
- 자세한 변경 흐름은 [Contract Lifecycle](contract-lifecycle.md)를 따른다.
