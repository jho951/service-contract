# Editor Operating Contract

Editor 서버의 운영 계약은 현재 `documents-service` v1 안정성 유지와 v2 전환 준비를 동시에 만족해야 한다.

## 배포 원칙
- v1 계약은 운영 기준으로 유지한다.
- main 확장안은 shared operation core + separated persistence 문서로 관리한다.
- Node 단일 영속 모델은 별도 미래 검토 문서로만 둔다.
- `Workspace` backup 코드는 `backup/workspace/` 아래에서만 관리한다.
- 운영 중 v1 스키마를 깨는 변경은 금지한다.
- 현재 런타임은 `documents-service:8083`을 기준으로 한다.

## 데이터 운영
- `Document`와 `Block`은 soft delete를 우선한다.
- hard delete는 운영 정리 또는 마이그레이션 후처리 용도다.
- `version`은 낙관적 락 충돌을 줄이기 위해 사용한다.
- 정렬 키 충돌과 순환 참조는 운영 데이터 정합성 검사에서 감지해야 한다.
- 현재 v1에는 별도 공유 캐시 계층이 없다.

## 마이그레이션 운영
- v1/v2 전환은 단계적으로 진행한다.
- 마이그레이션 전후에 데이터 수, 부모 관계, 정렬 순서를 검증한다.
- 롤백 가능성을 확보한 뒤에만 대규모 전환을 진행한다.

## 백업 / 복구
- `Workspace` 관련 backup 코드는 별도 경로에서만 보관한다.
- 복구 작업은 관리자 또는 배치 작업으로 제한한다.
- 복구 후에는 문서 트리와 블록 트리 정합성을 다시 검증한다.

## 장애 대응
- soft delete 오작동, 순환 참조, 정렬 충돌, content schema 오류는 우선순위 높은 운영 이슈로 다룬다.
- 장애 대응 시 기존 계약을 바꾸기보다 입력 검증과 정합성 검사로 먼저 대응한다.

## 릴리스 체크리스트
- v1 API 호환성 유지
- editor OpenAPI 반영
- 계약 문서 갱신
- sync 파일 갱신
- smoke test 및 주요 흐름 검증
