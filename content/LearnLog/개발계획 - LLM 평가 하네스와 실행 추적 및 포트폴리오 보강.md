---
date: 2026-10-14
type: plan
status: proposed
tags:
  - LearnLog
  - LLM평가
  - 개발계획
  - 포트폴리오
---

# LearnLog 개발계획 — LLM 평가 하네스·실행 추적·포트폴리오 보강

> 계획서입니다. 아래의 파일·모델·명령·화면은 향후 구현 제안이며 아직 구현되지 않았습니다.
> 기준 코드: `317ad81224f3673ad7eb06ff9638ac53519e3c6b` (2026-10-14 로컬 HEAD).
> 근거: 기존 LearnLog 개발문서 35편, 현재 서비스·실험 스크립트·CI 코드, 제출 자료, 잡코리아 실제 공고 검토.
> 채용 검토: [[채용공고 검토 - LearnLog 평가 시스템 보강의 효용 2026-10-14]]

## 0. 이번 작업으로 무엇을 완성할 것인가

**같은 평가 입력으로 LearnLog의 변경 전후를 실행하고, 품질·지연·토큰·실패 원인을 비교하여 변경을 채택할 근거를 남기는 작은 평가 시스템을 만든다.**

기존 작업은 단발 벤치마크와 JSONL이 축적된 상태다. 이번에는 다음 질문에 일관된 방법으로 답할 수 있게 묶는다.

1. 현재 프롬프트와 모델이 실제 서비스에서 쓰는 것과 같은가?
2. 바꾸면 기존에 잘 답하던 질문이 깨지는가?
3. 오류가 검색·라우팅·생성·후처리·검증 중 어디서 생겼는가?
4. 가드가 문제를 걸러냈기 때문에 좋아 보이는가, 생성 결과 자체가 좋아졌는가?
5. Judge가 틀린 판정을 내리는가?
6. 개선된 품질을 얻는 데 호출·토큰·대기 시간이 얼마나 추가되는가?
7. 제3자가 원시 결과를 보고 같은 집계를 재현할 수 있는가?

이 작업은 앞서 논의한 네 항목을 연결한다.

| 항목 | 구현 결과 | 채용에서 보여줄 증거 |
| --- | --- | --- |
| 1. 평가 구조 정리 | 버전 고정 데이터셋·실행·평가 결과 | 테스트 가능한 입력과 기준을 설계함 |
| 2. 변경 전후 비교 | baseline/candidate 비교·회귀 목록 | 품질을 측정하고 변경을 판단함 |
| 3. 실행 기록 | 단계별 trace·토큰·재시도·폴백 | 병목과 조용한 실패를 추적함 |
| 4. 포트폴리오 반영 | 비교 보고서·화면·재현 방법 | 구현과 검증 결과를 설명할 수 있음 |

### 추천 범위

- **V1 필수**: 파일 기반 하네스 + 현재 서비스 연동 + 고정 데이터셋 + 결정적 평가 + Judge 검증 + 비교 보고서.
- **V2 권장**: Django 읽기 중심 평가 콘솔 + 결과 DB 저장 + 수동 검토 기록.
- **V3 공통 확장**: 문서 수집·전처리·청킹과 검색 평가를 우선하고, Python API·권한·긴 작업 처리 계약을 보강한다. Local LLM / OpenSearch / Tool Calling / React는 역할 범위를 넓힐 때 하나씩 선택한다.

V1에서 실제 비교 결과를 얻기 전에 화면부터 만들지 않는다. 첫 실험은 가설과 기준을 정하고 실행한다. 개선이 관찰되지 않아도 실패 원인과 채택하지 않은 이유가 남으면 유효한 산출물이다.

## 1. 문서·현재 코드 대조에서 나온 설계 전제

### 1.1 현재 모델과 과거 모델을 구분한다

현재 코드의 상수는 다음과 같다. 외부 서비스의 오늘 가용성은 이번 계획 수립 중 실제 API 호출로 확인하지 않았다. 구현 착수 시 기존 헬스체크를 실행하여 확인한다.

| 용도 | 현재 코드의 모델 | 주요 예산 |
| --- | --- | --- |
| 답변 생성 | Groq `openai/gpt-oss-120b` | 3000, 스트리밍 |
| 마크다운 변환 | 같은 ANSWER_MODEL | 4000 |
| path_trace·generation_compare 생성 | 같은 gpt-oss | 3000, JSON 모드 |
| 라우팅·검색어·태그·모순 검증 | Groq `qwen/qwen3.8-27b` | 호출별 40~300 등 |
| 일일 요약·보조 코멘트 | Qwen 경량 모델 | 150 / 120 등 |
| 임베딩 | Mistral `mistral-embed` | 1024차원 |

`68초 → 37초`는 과거 Mistral 구성의 개선 사례다. 지금 구성의 전체 응답 시간으로 재사용하면 안 된다. 모델 교체 문서의 약 5초도 답변 생성 측정값이며 검색·후처리·저장까지 포함한 사용자 완료 시간과 같지 않다.

### 1.2 과거의 중요한 관측을 정확한 이름으로 남긴다

| 기존 표현/관측 | 앞으로의 해석 |
| --- | --- |
| 오류율 10% → 5% | 기존 모델·데이터·Judge 기준의 step 판정 8/80 → 4/80. 모호한 판정 포함 여부를 별도 확인 |
| 최종 불일치 0/91 | 20회 실행에서 나온 91개 최종 step의 index-value 불일치 0건 |
| 가드가 남은 5%를 제거 | 직접 증명되지 않음. 당시 평균 호출 1.0회이고 재생성 발동이 없었음 |
| 두 Judge 일치율 73% | Judge 간 합의도. 사실 정확도 73% 또는 Claude 정답률을 의미하지 않음 |
| 검색 추가 0.65초 | 당시 표본·데이터 규모의 관측. 1만 건에서도 동일하다는 성능 보장은 아님 |
| 테스트 개수 | 현재 수집 결과와 기준일을 확인한 뒤 통일. 함수 개수와 pytest 수집 케이스 수는 다름 |

**0/91은 사실적으로 올바른 정답 91개라는 뜻이 아니다.** 둘 다 동일한 오답이면 내부 일관성 검사를 통과한다. 또한 step들은 한 번의 생성 안에 묶여 있으므로 독립 표본 91개로 취급하지 않는다.

### 1.3 개발문서의 체크박스를 현재 TODO로 그대로 옮기지 않는다

선택지 품질 문서에 미완료로 남은 `vendor-mixup`, 중복 distractor index 검사, 감사 기록, 최소 step 수 정책 중 일부는 현재 코드에 반영돼 있다. 최신 코드가 증거이며 문서는 당시 결정의 배경이다.

반대로 현재 코드의 `_audit`는 탈락 사유를 남기지만 탈락한 문항 전문·안정적인 원본 step ID까지 충분히 보존하지 않는다. 지금 상태로는 과거 탈락 문항을 다시 사람이 판정하기 어렵다. 하네스에서 API 원시 응답과 모든 필터 전후 상태를 보존해야 한다.

## 2. 기존 문서에서 추출한 요구사항

| 실제 경험 | 평가 시스템에 넣을 요구사항 | 연결 문서 |
| --- | --- | --- |
| 정규식 채점 오판 75% | 채점기 자체를 사람 라벨과 대조, 재채점 가능 | [[프롬프트 변경 효과 측정 - correct_index 오류율 비교 테스트]] |
| 휴리스틱 스킵 90% | 실패·미판정·대상 아님을 통과와 분리, coverage 표시 | [[프롬프트 검증 재설계 - pytest를 버리고 실험 스크립트로]] |
| index-value 혼동 | 구조 일관성과 사실 정답을 별도 평가 | [[correct_index 런타임 가드 — 정답 인덱스 정합성 검증]] |
| 품질 게이트가 버린 결과 소실 | 원시 문항과 탈락 사유 모두 보존 | [[선택지 문제 품질 게이트 - 멀티에이전트로 설계 검토하기]] |
| 현재 프롬프트와 실험 복사본 불일치 | 현재 프롬프트 공통 빌더 + 실행 시 hash·전문 고정 | [[쓰던 모델 4개가 한꺼번에 죽었다 - 교체와 CI가 못 잡은 이유]] |
| 모델 폐기·200 빈 출력 | 가용성 검사와 코드 CI·품질 평가를 분리 | 같은 문서 |
| 공식 문서 검색 실패 | 검색어·도메인·순위·실제 발췌 평가 | [[RAG 검색 파이프라인 개선 — 한국어 질문이 엉뚱한 결과를 부르던 문제]] |
| 꼬리질문 픽스처 주제 누설 | 단계 격리 평가와 전체 경로 평가를 별도 표시 | [[꼬리질문 - self-FK 질문 트리 구현]] |
| 생성과 검증의 500/1500 불일치 위험 | 사용 컨텍스트 snapshot 재사용, hash 검사 | [[코드 청소 - 중복·죽은 경로·조용히 저장되던 버그]] |
| Groq 무관/모순 혼동 | contradiction·unsupported·irrelevant 라벨 분리 | [[환각 방어 - 예방·검출·표시 3단]] |
| 입력이 아니라 출력이 병목 | 입력·출력·추론 토큰, TTFT, 전체 시간을 별도 기록 | [[LLM 추론에서 입력은 싸고 출력이 비싸다]] |
| 작은 사용자 수 | 선택률·학습 효과를 무리하게 통계화하지 않음 | [[선택지 문제 품질 게이트 - 멀티에이전트로 설계 검토하기]] |
| Streak·일일 일지 자동 생성 | 평가 출력이 개인 학습 기록에 저장되지 않도록 격리 | [[일일 학습일지]], [[통계 대시보드 + Streak(불꽃) 시스템 구현]] |
| SSE 중 오류 문자열 정상 저장 | 인프라 실패와 모델 출력 분리, 저장 부수효과 테스트 | [[코드 청소 - 중복·죽은 경로·조용히 저장되던 버그]] |
| 마크다운 변환만 잘림 | 답변과 후처리의 finish_reason을 각각 기록 | 현재 `test_markdown_fallback.py` 및 HEAD 수정 |
| Render 워커 timeout | 평가 배치를 웹 요청에서 실행하지 않음 | [[Gunicorn 워커 타임아웃 트러블슈팅 - 스트리밍 응답 SIGKILL]] |

## 3. 전체 구조와 책임

흐름은 `Dataset snapshot → Run manifest → Target 실행 → 원시 결과·Trace → Evaluator → Result → Comparison → 사람 판단`이다.

### 3.1 V1 저장 구조

아래는 제안 구조이며 이번에는 생성하지 않았다.

```text
evaluation/
  datasets/                 # 검토 완료 입력·라벨, Git 버전 관리
    path_trace_v1.jsonl
    search_route_v1.jsonl
    judge_calibration_v1.jsonl
    regression_v1.jsonl
    manifest.json
  targets/                  # 현재 서비스 로직을 호출하는 어댑터
  evaluators/               # 구조·검색·Judge·요약 평가
  runner.py                 # 예산·속도·상태·재개
  compare.py                # 비교 가능성 확인·회귀 목록
  import_legacy.py          # 과거 JSONL 정규화
  reporting/                # Markdown/JSON 결과
  tests/                    # 외부 API 없는 하네스 계약 검증

artifacts/evaluation/<run_id>/
  manifest.json             # 변경 불가 실행 설정
  cases.jsonl               # 해당 실행의 입력 snapshot
  events.jsonl              # 단계·API 요청 완료 이벤트
  outputs.jsonl             # 필터 전후 원시 출력
  evaluations.jsonl         # evaluator revision별 결과
  summary.json
  report.md
```

대용량 원시 결과는 Git에 전부 올리지 않는다. 작은 공개용 샘플과 재현 안내만 저장소에 넣고, 완전한 결과는 로컬/CI Artifact로 보존한다. CLI는 로컬 또는 별도 프로세스에서 실행한다.

### 3.2 현재 서비스와 연결할 위치

| 기존 위치 | 제안 변경 | 이유 |
| --- | --- | --- |
| `ExerciseService._gen_path_trace` | 프롬프트 조립을 순수 함수로 추출 | 실험 복사본과 drift 제거 |
| `_call_json`, `_gen_and_validate` | 관측용 recorder를 선택적으로 전달 | 원시 JSON·사용량·첫/재생성 시도 보존 |
| `_filter_valid_steps`, `_apply_quality_gates` | 원본 step ID를 유지한 감사 결과 반환 | 탈락·통과 추적과 재평가 |
| `LearnlogService._build_answer_prompt` | 현재 빌더 재사용 | 복제 없이 같은 입력 전달 |
| `_build_web_context`, `_build_retrieved_context` | 실제 사용 순서·발췌 snapshot 기록 | URL·DB 상태가 바뀌어도 판정 근거 보존 |
| `build_search_agent` | 평가 모드에서 recorder 연동 | retrieve/router/web/generate 단계 추적 |
| `generate_answer_stream` | usage/finish_reason/첫 본문 이벤트 계측 | generation TTFT·출력·잘림 분리 |
| `extract_tags`, `convert_to_markdown` | 폴백 여부·원인·모델 호출 정보를 기록 | 200 실패·내용 손실 관측 |
| `check_consistency` | 사용 컨텍스트와 실제 3000자 검사 범위 기록 | Judge가 본 범위와 안 본 범위 구분 |
| `QuerySSEView` | 기존 사용자 경로의 회귀 검증만 우선 | 평가 배치가 웹 워커를 점유하지 않게 함 |

현재 그래프만 실행하면 후처리·DB 저장·백그라운드 검증은 포함되지 않는다. `target=search_graph`와 `target=query_full`의 포함 범위를 manifest에 명시한다. query_full은 그래프 + 후처리 + 저장을 흉내내는 것이 아니라 실제 공통 로직을 재사용하되 평가 저장소에만 결과를 남기는 경로로 정의한다.

### 3.3 어댑터 계약

모든 target은 입력 snapshot·실행 설정·recorder를 받아 다음을 돌려준다.

- output: 답변/문항/라우팅 결정 등 target별 결과.
- status: 성공·실패·부분 결과·취소.
- metadata: 모델·프롬프트·컨텍스트·실행 경로.
- diagnostics: 가드·폴백·재시도·원시 step.

출제 어댑터는 `_generate_content`에 해당하는 생성 로직을 재사용한다. `generate_exercise()`는 실제 Exercise 행을 생성하므로 평가에서 직접 호출하지 않는다. 검색 어댑터 역시 `save_learning_log()`를 호출하지 않는다.

기존 사용자 UI의 학습자 자가 채점 정책은 유지한다. 하네스의 품질 평가가 학습자의 점수를 대신 매기는 기능으로 들어가면 기존 UX 설계 의도와 충돌한다.

## 4. 데이터 계약 — Case, Run, Result, Trace

### 4.1 EvalCase

| 필드 | 내용 | 필수성 |
| --- | --- | --- |
| case_id | 의미 있는 안정 ID: `pt-shifted-001` 등 | 필수 |
| revision | 입력/라벨 수정 버전 | 필수 |
| suite / target | 출제·검색·라우터·Judge·장애 등 | 필수 |
| tags | 숫자형/한국어/꼬리질문/무관 컨텍스트 등 | 필수 |
| input | query, 학습 답변 snapshot, 부모/루트 질문 등 | 필수 |
| context_snapshot | 고정 로그·웹 발췌·순서·출처·버전 | 필요한 target |
| expected | 정확한 결과 또는 반드시/금지 조건 | 필수 |
| severity | critical / normal / diagnostic | 필수 |
| source | 실제 장애·개발문서·수작업 신규 | 필수 |
| split | development / holdout | 필수 |
| label_status | draft / reviewed / disputed | 필수 |
| evidence | 정답 근거 URL·인용 구간·버전·확인일 | 사실 평가 |

gold는 LLM이 생성한 `correct_answer`가 아니다. 사람이 공식 근거를 보고 검토한 기대 조건이다. 자동 생성 문항은 매번 다르므로 입력 Case와 생성된 step artifact를 분리한다. 생성된 step의 의미 판정은 step별 사람/Judge 결과를 붙인다.

### 4.2 EvalRun manifest

필수 정보: UUID run_id, 실행명, UTC 생성일/한국시간 표시, 코드 commit, dirty 여부, 미커밋 내용 hash, 데이터셋 revision/hash, target 버전, evaluator 목록/revision, provider, requested_model, response_model, SDK 버전, temperature, max_tokens, reasoning 옵션이 실제 지원될 때의 값, 프롬프트 hash·snapshot, 컨텍스트 정책, 반복수, 순서 seed, 동시성, 제한 시간, 최대 호출/토큰 예산, 환경, mode, 비교 목적, 변경 가설.

- API가 실제 모델 ID를 반환하지 않으면 `response_model=unknown`으로 남긴다.
- 모델 alias만 있으면 hash로 모델 자체가 고정됐다고 주장하지 않는다.
- dirty 작업도 탐색 실행은 허용하되 공개 비교는 commit된 상태를 원칙으로 한다.
- 실행 이후 바뀐 서비스 상수를 이전 manifest에 덮어쓰지 않는다.
- 전체 비밀키/인증 헤더는 기록하지 않는다.

### 4.3 EvalResult

결과 단위는 `(run_id, case_id, case_revision, repetition, attempt, evaluator_revision)`으로 식별한다.

실행과 평가는 서로 독립적인 상태를 가진다.

| 실행 상태 | 의미 |
| --- | --- |
| pending / running | 아직 결과 없음 / 실행 중 |
| succeeded | target 실행 완료 |
| failed | API·파싱·스키마 등 실행 실패 |
| interrupted | 호출 완료 여부가 불명확한 중단 |
| cancelled | 명시적 취소 |

| 평가 상태 | 의미 |
| --- | --- |
| pass / fail | 해당 평가 기준에서 통과/실패 |
| review_required | 모호하거나 근거 부족으로 사람 검토 필요 |
| error | evaluator 자체 실패 |
| not_applicable | 해당 결과에 적용되지 않는 기준 |

각 metric은 `name, value, unit, numerator, denominator, verdict, reason, evidence, evaluator_revision`을 가진다. `error`, `review_required`, `not_applicable`을 통과로 변환하지 않는다.

### 4.4 Trace와 API attempt

각 span에 `trace_id, span_id, parent_span_id, stage, start_offset_ms, duration_ms, status, requested/response_model, request_id, usage, finish_reason, retry_no, fallback_reason`을 저장한다.

추천 stage: retrieve_logs, embed_query, router, query_rewrite, web_search, build_context, answer_generate, extract_tags, markdown_convert, exercise_generate, index_guard, quality_gate, consistency_judge, report_write.

- elapsed 측정은 monotonic clock, 기록 시각은 timezone-aware UTC.
- 병렬 태그/마크다운 span은 합계가 전체 wall time보다 길 수 있다. 합산해서 end-to-end 시간으로 보고하지 않는다.
- 생성 TTFT는 생성 요청 시작부터 첫 **비어 있지 않은 본문**까지.
- 사용자 첫 답변 시간은 요청 시작부터 첫 본문 SSE까지. 검색·라우터 시간이 포함된다.
- 이벤트 첫 도착과 첫 본문 토큰은 별개다. reasoning 전용 이벤트를 답변 TTFT로 세지 않는다.
- 스트리밍 usage 미지원/미수집은 null. 문자열 길이를 토큰 실측값으로 채우지 않는다.
- completion_tokens와 reasoning_tokens의 포함 관계는 provider 응답 정의에 맞춰 별도 기록하며 두 번 더하지 않는다.

## 5. 데이터셋 구성 — 작게 시작하되 실패 유형을 빠뜨리지 않는다

초기 수치는 작업량을 정하기 위한 제안이며 통계적 검정력을 보장하는 표본 수가 아니다.

### 5.1 V1 준비 데이터셋: 60개

| suite | 개수 | 구성 | 실행 특성 |
| --- | --- | --- | --- |
| 출제 품질 | 12 | 숫자/서술/꼬리질문/충분·부족 근거 | 실제 생성 |
| 검색·라우팅 | 12 | 키워드/의미/없는 주제/최신 API/부모 맥락 | 고정 corpus + 실제 임베딩/라우터 |
| Judge 교정 | 24 | 모순/일치/근거 없음/무관 각각 6 | 저장된 답변 재판정 |
| 조용한 실패·구조 회귀 | 12 | 빈 출력/잘림/중복 index/재시도 등 | 외부 API 없는 replay |

출제·검색은 8 development + 4 holdout, Judge는 각 라벨 4 development + 2 holdout으로 구성한다. 장애 suite는 항상 전체 replay로 실행한다. holdout은 같은 원문을 조금 바꾼 형제 질문을 development에 섞지 않으며, 동일 원문/스레드 단위로 split한다.

최초 smoke는 이 중 development 대표 5~6개만 실행한다. 모든 suite를 한 번에 실API로 반복하지 않는다.

### 5.2 대표 Case 설계

| ID 제안 | 실패를 자극할 입력 | 기대 조건 |
| --- | --- | --- |
| pt-shifted-001 | 참조 카운팅, 값≠인덱스 | index-value 정합 + 의미 정답은 별도 검토 |
| pt-descriptive-001 | JWT/트랜잭션의 조건부 설명 | 하나의 정답, 오답 근거가 설명 가능 |
| pt-followup-001 | '그거 해결하려면?' + 부모/루트 | 문제 자체에 기술·맥락 명시 |
| ret-semantic-001 | 'ORM 쿼리 반복 호출' | N+1 근거 로그가 top-3에 포함 |
| ret-keyword-001 | select_related 등 정확한 용어 | 관련 로그 우선 검색 |
| ret-nodata-001 | corpus에 없는 주제 | 관련 gold 없음, 억지 검색을 성공으로 세지 않음 |
| route-sensitive-001 | 버전·API 시그니처 질문 | 웹 필요 true |
| route-irrelevant-001 | 무관 로그만 제공 | use_logs false |
| rewrite-followup-001 | 모호한 꼬리질문 + root | 영어 검색어에 핵심 기술·의도 보존 |
| dom-boundary-001 | django / javascript / go언어 | substring 오매칭 회귀를 결정적으로 검사 |
| judge-irrelevant-001 | 문맥과 전혀 다른 참/거짓 미확정 답변 | 무관함을 모순으로 강제 분류하지 않음 |
| judge-contradict-001 | 근거 A, 답변 not-A | 모순 판정 |
| judge-unsupported-001 | 근거에 없는 API 주장 | unsupported로 따로 검토; 기존 모순 Judge 한계 기록 |
| judge-tail-001 | 오류를 답변 3000자 뒤에 배치 | 검사 범위 밖이라는 사실 표시 |
| quiet-empty-001 | API 200 + 빈 본문 | 실행 실패 또는 폴백, pass 금지 |
| quiet-mdcut-001 | 정상 답변 + length 마크다운 | 원문 폴백과 변환 잘림 사유 기록 |
| quiet-stream-001 | 토큰 일부 이후 예외 | error, 학습 DB 저장 0건 |
| gate-duplicate-001 | distractor index 중복 | gate 거부와 원시 payload 보존 |
| gate-no-meta-001 | distractors 없음/빈 배열 | KeyError 등 비정상 경로 관측, 원하는 실패 계약 정의 |
| retry-minsteps-001 | 1차 2step, 2차 3step | 2회 시도·최종 선택·discarded 결과 모두 추적 |
| shuffle-001 | 화면 보기 순서 변경 | 제출 원본 index와 서버·화면 정답 표시 일치 |

위 기대 조건은 현재 코드가 모두 통과한다는 선언이 아니다. 현재 baseline을 측정할 때 실패가 나오면 재현 fixture로 남기고, 별도 수정 작업의 근거로 사용한다.

### 5.3 gold 검토 절차

1. 개발문서·실제 원시 결과에서 실패 후보를 추출한다.
2. 입력의 버전·플랫폼 조건을 명시한다.
3. 공식 근거를 확인하고 expected_fact / forbidden_claim을 작성한다.
4. 같은 근거로 다른 날 다시 확인하여 애매한 라벨은 disputed로 남긴다.
5. Judge가 접근할 입력과 평가에만 쓰는 gold를 구분한다.
6. reviewed 항목만 대표 정확도 지표에 넣는다.

주의: `_common.py`의 HTTP 301/302 캐시 동작·리다이렉트 횟수, Python 참조 카운팅처럼 환경에 따라 달라지는 예시는 기존 문자열을 gold로 그대로 승격하지 않는다. 조건 없이 일반화된 설명을 먼저 재검토한다.

## 6. 평가 기준 — 무엇을 어디까지 증명할 것인가

### 6.1 출제: 세 층

**구조 검증**: JSON 파싱, top-level object, scenario/steps 타입, step 3~5개 요구, choices 정확히 4개 문자열, 중복 선택지, ci가 bool이 아닌 정수인지, 범위, correct_answer 포함·정합, distractor index 완전성·중복, why·type 형식.

현재 `isinstance(True, int)`도 참이다. bool index, 리스트가 아닌 choices, dict가 아닌 step, 없는 meta 등의 payload는 결정적 fixture로 검토한다. 검사 강화가 필요하면 본 계획의 향후 구현 단계에서 수정하고 새 회귀 테스트를 남긴다.

**품질 신호**: length-bias, absolute-word-skew, correct-index-fixed, one-step-short 존재, 오답 type 다양성. 발생률을 기록하되 사실 정확도로 합산하지 않는다. 문항을 강제 거부하는 정책을 바꿀 때는 사람 판정과 비교한 오탐·누락·yield를 먼저 본다.

**의미 검토**: 사실적 정답 여부, 정답의 유일성, explanation의 정답과 일치, 오답 why의 타당성, 맥락 없이 이해 가능, 근거 밖 지식 필요 여부. 자동 Judge는 보조이며 gold/사람 검토와 대조한다.

반드시 첫 생성과 최종 출력을 분리해 집계한다.

| 지표 | 분자/분모 |
| --- | --- |
| 첫 생성 파싱 실패율 | 파싱 실패 API 응답 / 최초 생성 시도 |
| 원시 index-value 불일치율 | 불일치 원시 step / 검사 가능한 원시 step |
| 구조 미검사율 | 구조가 깨져 검사 불가 step / 전체 원시 step |
| 최종 구조 통과율 | 적합 최종 step / 최종 step |
| step 생존율 | 채택 step / 해당 시도의 원시 step |
| 사용자 제공 가능률 | 최소 step 등 계약 충족 세트 / 출제 요청 |
| 재생성률 | 재생성 발생 요청 / 출제 요청 |
| 의미 정답률 | 사람/gold 정답 step / 의미 판정 완료 step |
| 의미 평가 coverage | 의미 판정 완료 step / 전체 대상 step |

모두 버린 뒤 오류율 0%가 되는 것을 방지하기 위해 최종 오류와 제공 가능률·생존율을 함께 표시한다.

### 6.2 검색·라우팅

- 고정 corpus에서는 relevant_doc_ids로 Hit@3, Recall@3, MRR@3을 계산한다.
- gold 관련 문서가 없는 Case는 Recall 분모에 넣지 않고 무관 문서 노출/차단을 따로 본다.
- 검색어 변환은 기술명·질문 의도 보존을 사람이 라벨한 조건과 비교한다.
- 라우터는 use_logs와 need_web 정확도를 별도로 계산한다.
- 중요한 기준은 사실 민감 질문에서 웹을 생략한 비율과 무관 로그를 주입한 비율이다.
- 도메인 적합과 문서 관련성은 다르다. official URL 비율이 높아도 질문의 답을 담는지 따로 검사한다.
- 웹검색은 실시간 결과를 기록하고 동일 결과 snapshot으로 생성만 재평가할 수 있게 한다.

고정 retrieval 실험과 live 웹 경로를 섞어 하나의 검색 정확도처럼 보고하지 않는다. 문서 제목·URL·발췌의 순서, 추출 길이, 실제 생성에 사용된 부분을 남긴다.

### 6.3 답변

주요 지표: 필수 사실 포함, 금지 주장 발생, 근거와 직접 모순, 근거에 없는 주장, 질문 해결에 필요한 내용 누락, 답변/후처리 잘림, 빈 출력, 코드 예제의 사전 정의된 조건 충족.

초기에는 정답 문장 전체를 exact match하지 않는다. 조건 목록과 근거 단위의 평가를 쓴다. 코드 실행 평가는 범위가 제한된 수작업 fixture에만 적용하며, 모델 생성 코드를 임의로 호스트에서 실행하는 기능은 V1에 넣지 않는다.

### 6.4 Judge 교정

24개 사람 검토 Case에 실제 운영 Judge를 실행한다. 라벨은 다음 네 가지다.

- supported: 대조 가능한 근거가 있고 일치.
- contradicted: 근거가 주장과 직접 충돌.
- unsupported: 대조 근거가 부족함.
- irrelevant: 제공 문맥이 다른 주제임.

현재 bool consistency 계약에 맞춘 평가에서는 contradicted만 모순 양성으로 둔다. unsupported/irrelevant를 사실상 정답으로 취급하지 않고 보조 진단으로 표시한다. 더 풍부한 Judge 스키마는 별도의 candidate 실험으로 비교한다.

산출물: 4분류 혼동표, 모순 탐지 precision/recall, 판정 coverage, 실패율, 모델간 합의도, 사람과의 불일치 목록. 양성 표본이 0이면 precision/recall을 0이나 100으로 채우지 않고 N/A로 표시한다.

사람 검토는 모델 이름·baseline/candidate 표시를 숨기고 진행한다. 다른 모델 재판정은 정답지가 아니라 불일치 탐색 수단이다. 자동 Judge 선택을 development로 튜닝하고 holdout으로 한 번 확인한다.

생성 모델의 숨겨진 추론 전체를 저장할 필요는 없다. 채점 이유는 근거 문장·충돌 지점 중심의 짧은 설명으로 저장한다.

## 7. 실행 모드와 재현성

| 모드 | 무엇을 고정/실행하나 | 사용 목적 |
| --- | --- | --- |
| replay | 저장 원시 출력에 평가기만 재적용 | 추가 생성 API 없이 채점기 비교 |
| fixed_context | 입력·corpus·웹 발췌 고정, 대상 모델 호출 | 프롬프트·모델 변경 분리 |
| fixed_corpus | corpus 고정, 검색/라우터/생성 실행 | retrieval과 라우팅 변경 검토 |
| live_pipeline | 그 시점의 검색 API와 현재 경로 | 서비스 현실성·운영 smoke |

과거 꼬리질문 실험처럼 검색 결과에 주제가 이미 적혀 있으면 생성 단계 평가에는 합리적인 고정 입력이지만, 전체 파이프라인의 맥락 해결 능력을 증명하지 않는다. 모드와 target 범위를 보고서 첫 줄에 표시한다.

baseline과 candidate는 같은 dataset/corpus snapshot을 쓴다. 프롬프트 비교 시 모델·예산·temperature·evaluator를 고정한다. 모델 비교 시 프롬프트를 고정하고 불가피한 provider 옵션 차이를 표시한다. 가드 비교는 같은 저장 원시 응답을 replay하여 필터 효과를 직접 비교한다.

외부 모델의 비결정성 때문에 재현성은 출력 동일성 보장이 아니다. 입력·설정·원시 결과·집계가 추적 가능하고 재분석 가능한 것을 목표로 한다.

### 비교 키와 판정

- Case revision, snapshot hash, evaluator revision이 다르면 직접 비교를 막거나 명확히 비동등 비교로 표시한다.
- generation 비교: case 단위로 반복 결과를 요약한 뒤 paired 비교한다. repetition 번호가 같은 두 출력이 같은 무작위 상태에서 나왔다는 뜻은 아니다.
- evaluation 비교: 동일 output artifact에 평가기 revision만 달리 적용한다.
- step-level 지표와 case-level 지표를 함께 제공한다. 5step 출력 Case가 3step 출력 Case보다 과도한 가중치를 갖지 않도록 macro 평균을 추가한다.
- 성공 Case 교집합의 품질과 전체 Case 성공률을 함께 표시한다. 실패 Case를 비교에서 조용히 빼지 않는다.
- 소표본에서는 차이의 방향·실패 예시·분모를 중심으로 보고한다. 유의미한 통계적 개선이라고 단정하지 않는다.

## 8. 실행기 — 실패·예산·중단·재개

### 8.1 상태와 영속화

각 Case를 시작하기 전에 running 이벤트를 기록하고, API 요청별 완료를 즉시 저장한다. 생성 완료 후 평가를 따로 저장하여 Judge 장애 때문에 생성 데이터를 다시 호출하지 않게 한다.

중단 후 재개는 성공 결과가 있는 `(case, repetition, target config)`를 건너뛴다. 응답은 받았는데 저장 전에 죽은 요청은 interrupted/unknown으로 남긴다. provider가 idempotency를 보장하지 않는 한 exactly-once API 호출을 주장하지 않는다.

V1은 단일 writer·동시성 1이다. JSONL 마지막 불완전 줄은 무시 후 진단 기록, 원시 파일 보존, 중복 키 감지. 두 프로세스가 같은 run 디렉터리를 쓰는 것은 lock으로 거부한다. V2 DB 저장에서는 unique constraint와 짧은 트랜잭션으로 중복 결과를 방지한다.

LLM 호출을 긴 DB transaction 안에 넣지 않는다. 설정 고정·결과 쓰기 구간만 짧게 처리한다.

### 8.2 예외 정책

| 실패 | 기본 처리 | 결과 표시 |
| --- | --- | --- |
| timeout / 일시적 5xx | 제한된 재시도, 최대 2회 추가 | 실제 호출수·대기시간·최종 실패 |
| 429 | Retry-After/한도 메시지를 보고 대기 또는 예산 중단 | rate_limited, quota_blocked 구분 |
| 401/403/404·요청 한도 0 | 동일 모델 반복 호출 중단 | 인증/권한/폐기 후보 |
| 200 빈 출력 | 실패 기록, 서비스 정책에 맞는 제한된 회복 | empty_output |
| length + 깨진 JSON | truncation과 parse_error 모두 기록 | 단순 품질 실패로 숨기지 않음 |
| Judge JSON 불량 | evaluator_error, 원시 생성 결과 보존 | 평가 coverage 감소 |
| 디스크/DB 기록 실패 | 해당 run 중단 | 조용한 성공 금지 |
| Ctrl+C | 현재까지 flush, interrupted 종료 | 미실행 수·재개 방법 |

SDK 자체 자동 재시도도 확인한다. runner와 SDK 양쪽의 무제한 재시도가 겹치지 않도록 정책을 한 곳에서 정하고 manifest에 실제 적용값을 남긴다.

### 8.3 호출량 계획

소규모 실험은 development 8개 × 2variant × 2반복 = 32개 target 실행으로 시작한다. 이것이 API 32호출이라는 뜻은 아니다.

예산은 `Case × variant × repetition × (target 단계 호출 + 서비스 재생성 + 인프라 재시도 + Judge)`로 계산한다. 검색 경로에는 임베딩·라우터·검색어 변환·Tavily·생성·태그·마크다운·Judge가 추가된다.

실행 전 dry-run에서 호출 예상치·최대치, 토큰 추정 범위, 활성 모델과 데이터 split을 보여준다. token estimate는 추정으로 표시한다. 운영 quota/가격은 착수 때 확인하고 계획에 과거 무료 한도를 고정하지 않는다.

- 최초: 동시성 1, 최대 요청/토큰/실행시간 제한을 설정.
- 모델별 limit를 따로 본다. 전체 interval 하나가 모든 모델 quota를 해결하지 않는다.
- 금액은 usage와 확인된 가격표가 있을 때만 추정 비용으로 계산.
- 무료 계정이어도 호출수/토큰 소비는 표시. 비용 unknown과 실제 0원을 구분.
- 재채점은 별도 eval pass로 저장해 생성 재호출을 피한다.

## 9. 최소 변경 실험 — 첫 결과를 무엇으로 만들까

추천 순서가 있다. 세 실험을 동시에 시작하지 않는다.

### 실험 A: 평가기를 먼저 믿을 수 있는가

- 대상: Judge calibration 24건 + 기존 원시 JSONL replay.
- baseline: 현재 consistency Judge.
- candidate: 모순·근거 없음·무관함을 분리한 스키마/지시.
- 고정: 같은 답변·같은 컨텍스트·같은 모델·예산.
- 판단: 모순 누락이 늘지 않으면서 무관 문맥 오탐이 줄었는가? 미판정/토큰/지연은 얼마나 늘었는가?
- 산출물: 혼동표, 사람이 검토한 대표 오탐 3~5건, 채택/보류 결정.

### 실험 B: 출제 품질 가드가 무엇을 바꾸는가

- 먼저 기존/합성 원시 payload에 현재 가드를 replay한다.
- baseline: 현재 프롬프트·정책.
- candidate: 한 가지 변경만 선택. 예: 오답 보완 처방을 포함한 재생성 지시.
- 측정: 최초 구조 오류, 제공 가능률, 의미 품질, 재생성률, 총 토큰, 최종 step 수.
- gate로 많이 버리기만 한 candidate를 품질 향상으로 채택하지 않는다.
- 원시 index-value 불일치·기본 구조 실패와 오답 의미 문제를 구분.

교정 처방은 V1 핵심 runner가 안정된 뒤 실험한다. 재생성에 실패 이유를 넣을 때 답변/보기/ci/distractors를 모두 다시 생성·검증하고 부분 치환으로 인덱스를 깨뜨리지 않는다.

### 실험 C: 컨텍스트 예산·라우팅의 품질/지연 균형

- baseline: 현재 500/1500 정책.
- candidate: 1개 정책만 변경. 예: 질문 관련 부분을 더 잘 제공하는 방식.
- 동일 corpus/웹 snapshot에서 생성 비교 후 live smoke를 별도로 실행.
- TTFT, 출력/추론 토큰, 잘림, 필수 사실 포함, 웹 생략 오판을 측정.
- 과거 2질문×2회 관측을 최신 모델에서 재확인한다.

## 10. Django 평가 콘솔 — V2에서 보여줄 것

V1 결과가 안정된 뒤 파일 결과를 DB로 import한다. 평가 실행은 CLI로 유지하고 화면은 읽기·검토 중심으로 시작한다.

### 10.1 최소 DB 모델: 네 개

| 모델 | 주요 내용 |
| --- | --- |
| EvaluationDataset | name, revision, hash, case snapshot(JSON), source metadata |
| EvaluationRun | manifest(JSON), dataset FK, 상태·시각·요약, artifact hash |
| EvaluationResult | run FK, case/repetition, input/output/raw/audit/trace(JSON), execution/evaluation 상태 |
| EvaluationReview | result FK, 검토자, 라벨, 사유, 근거, 시각 |

Case가 Git 파일로 관리되는 동안 모든 Case를 별도 ORM 모델로 만들 필요는 없다. Result의 evaluator 결과 목록은 JSON으로 시작한다. 수십만 span 조회가 필요해질 때 Trace 테이블을 분리한다.

조회에 필요한 run 상태·시각·target, case_id·평가 상태는 컬럼/인덱스로 둔다. 가변 provider metadata와 raw payload는 JSON에 둔다. Result unique: `(run, case_id, case_revision, repetition)`; 재시도는 내부 attempts로 구분하고 재채점 revision별 결과를 추가 보존한다.

FK는 보호 정책을 적용한다. 학습 로그 삭제가 평가 증거를 연쇄 삭제하지 않게 snapshot을 쓰고, 실제 LearningLog FK는 출처 참조가 필요할 때만 nullable로 붙인다.

### 10.2 화면 세 개

**실행 목록**: 이름, target/mode, dataset, 모델/프롬프트 버전, 성공/실패/미판정, 시작 시각. 단순 점수 순위로 정렬하지 않는다.

**실행 비교**: baseline/candidate 선택, 비교 가능 여부, 가설·설정 차이, 품질/완료율/latency/토큰 변화, 개선·회귀·변화 없음·미판정 Case 목록. 실패 Case부터 필터 가능.

**Case 상세**: 입력과 실제 컨텍스트, 두 출력, 평가 사유, 원시 생성/최종 결과, 탈락 문항, 재시도, timeline, 사람이 라벨/근거 기록. 정답·오답 메타를 학습자 화면과 공유하지 않는다.

기존 HTMX/Django Template을 재사용한다. 숫자·비교 표·상태 필터면 충분하다. React 경험은 풀스택 직무군으로 범위를 넓힐 때 별도 선택 작업으로 판단한다.

### 10.3 권한과 공개 데모

- 로컬 콘솔은 기존 Django admin/staff 로그인으로 보호.
- 공개 채용 데모는 민감 정보 없는 고정 결과의 읽기 전용 snapshot.
- 공개 화면에서 실API 평가 실행·모델/프롬프트 수정·개인 학습 로그 조회를 제공하지 않음.
- DB import는 run ID·artifact hash를 검사하고 반복 import가 중복 행을 만들지 않아야 함.
- 직접 작성한 질문/답변만 공개용으로 선택하고 오류 메시지에 포함된 header·키를 제거.

이는 단순한 가상 위험 대응이 아니라, 현재 1인용 앱에 평가 실행 버튼을 넣을 때 타인이 API quota를 소비할 수 있는 구체적인 동작을 제한하는 설계다.

## 11. CI·헬스체크·품질 평가의 역할

| 검사 | 질문 | 시점 | 외부 API |
| --- | --- | --- | --- |
| 결정적 CI | 코드·파서·가드·비교 계약이 맞는가 | 기존 push/PR |
| Model Healthcheck | 모델 접근·응답/JSON/차원이 유효한가 | 기존 예약/수동 | 사용 |
| Offline quality eval | 이 변경이 품질을 바꾸는가 | 모델/프롬프트 변경 때 수동 | 필요한 부분만 |
| Live smoke | 실제 검색/스트리밍/후처리가 연결되는가 | 변경 후·출시 전 소수 Case | 사용 |

기존 예약 헬스체크를 다시 만들지 않는다. 시크릿 등록과 첫 성공 여부는 현재 문서 TODO만으로 완료했다고 간주하지 않는다. 다음 구현 단계에서 실제 Actions 기록을 확인한다.

healthcheck 예산 표에 답변 2000이 있으나 현재 생성은 3000, 변환은 4000이다. 이것이 의도적 최소 예산 검사인지 stale 설정인지 확인하고 task configuration과 연결한다. 단순 짧은 문장 성공은 긴 실제 답변의 잘림/빈 출력까지 증명하지 못한다.

CI에 실API 품질 평가를 무조건 blocking으로 넣지 않는다. 초기에는 보고서를 artifact로 남기고 판정은 사람이 한다. 외부 접근 실패·미판정이 있는 실행을 품질 통과로 표시하지 않는 gate는 필수다.

## 12. 검증할 테스트와 완료 조건

### 12.1 하네스 계약

- Case ID 중복·미검토 gold·revision/hash 불일치 탐지.
- 현재 prompt builder와 평가 target이 같은 입력에서 같은 프롬프트를 만들며, 과거 frozen template과 혼동하지 않음.
- raw payload deep copy 후 필터 적용: 원시 응답 변경 0.
- type 불량·bool index·choices 길이/중복·meta 누락의 예상 실패 계약.
- 최초/재생성/채택 결과·탈락 사유를 모두 저장.
- JSONL 부분 쓰기 후 재개, 중복 완료 Case 재호출 방지.
- 실패/skip/review_required가 pass 분모로 들어가지 않음.
- 같은 raw output 재채점 시 추가 생성 API 호출 0.
- mismatch dataset/evaluator run의 직접 비교 거부.
- query_full 평가 후 LearningLog/Exercise/Attempt/Streak/DailyJournal 변경 0.
- 병렬 span 합계와 wall-time을 올바르게 구분.
- provider usage 누락 시 null, 추론 토큰 이중 집계 없음.

### 12.2 서비스 회귀

- 토큰 도중 예외는 error 이벤트로 종료하고 학습 기록 저장 없음.
- 200 빈 답변·파싱 불가 JSON·length 변환을 성공으로 저장하지 않음.
- 생성/검증이 같은 컨텍스트 snapshot·절삭 정책을 사용.
- 기존 path_trace 셔플 원본 index와 서버 채점·화면 표시 일치.
- 기존 generation_compare의 답 공개 시점·자가 채점 정책 유지.
- 동일 API 요청 재시도와 품질 재생성을 각각 계측.

### 12.3 실제 실행 검증

1. 외부 API 없는 전체 replay를 통과시킨다.
2. 5개 smoke Case로 수집 필드·원시 결과·집계가 연결되는지 확인한다.
3. 중간에 수동 중단하고 재개해 중복/누락·부분 상태를 확인한다.
4. development 비교 1건을 수행한다.
5. 사람 검토로 자동 평가 오판을 확인한다.
6. 기준을 고정한 뒤 holdout을 실행한다.
7. 공개 샘플만으로 보고서 집계 재현을 확인한다.

이번 계획 수립에서는 새 테스트·실API 호출·서비스 실행을 하지 않았다. 이전 검토에서 로컬 pytest가 없고 Docker daemon이 꺼져 있었으므로 실제 실행 환경 준비도 P0에 포함한다.

## 13. 단계별 실행 티켓

모든 티켓은 코드 수정 범위·검증·산출물이 있다. 처음에는 순서대로 진행한다.

| ID | 작업 | 선행 | 완료 기준 | 예상 집중시간 |
| --- | --- | --- | --- | --- |
| P0-1 | 현재 commit·서비스 상수·테스트/헬스체크 범위 목록 | 없음 | 기준선 문서와 과거 수치 ledger | 2~3h |
| P0-2 | 원시 JSONL schema inventory·legacy 의미 분류 | P0-1 | schema별 import mapping·unknown 목록 | 3~4h |
| P0-3 | 공고 공통요건·필수 범위 확정 | 없음 | 공통 기반과 전문 선택 역량 구분 | 1h |
| P1-1 | Case 60개 초안·출처 연결 | P0 | 중복 제거·split·라벨 초안 | 5~7h |
| P1-2 | gold 공식 근거·사람 검토 | P1-1 | reviewed/disputed 구분·근거 snapshot | 4~6h |
| P1-3 | Case/Run/Result/Trace schema·metric 단위 확정 | P0 | sample artifact와 denominator 규칙 | 3~4h |
| P2-1 | 현재 출제 prompt builder 공통화 | P1-3 | current target drift 테스트 | 2~4h |
| P2-2 | 단일 writer runner·중단/재개·예산 | P1-3 | replay에서 재개/실패 테스트 통과 | 5~7h |
| P2-3 | path_trace 어댑터·raw/audit 수집 | P2-1/2 | 최초/최종/탈락/재생성 모두 저장 | 4~6h |
| P2-4 | 결정적 evaluator·legacy importer | P2-2 | schema fixture·재집계 일치 | 4~5h |
| P3-1 | graph/후처리 recorder·usage·TTFT | P2 | 서비스 부수효과 0·span 정합 | 5~7h |
| P3-2 | context snapshot·검색/라우터 평가 | P3-1 | frozen corpus 지표·route metrics | 4~6h |
| P3-3 | Judge calibration·사람 검토 | P1-2/P2 | 혼동표·미판정·대표 오판 | 4~6h |
| P4-1 | 비교 가능성 guard·report exporter | P2/P3 | 회귀 Case와 분모 재현 | 3~5h |
| P4-2 | development 1개 실험 + holdout | P4-1 | 판정 가능한 비교 또는 한계 명시 | 4~7h + 대기 |
| P4-3 | CI replay·healthcheck 접점 | P4-1 | 검사별 책임과 실패 상태 확인 | 2~3h |
| P5-1 | Django 4모델·import·admin | V1 완료 | 중복 import 방지·보존 정책 | 4~6h |
| P5-2 | 목록/비교/Case 상세 화면 | P5-1 | 3화면·수동 검토·공개 데이터 격리 | 6~9h |
| P5-3 | 데모·권한·결과 export | P5-2 | 외부 쓰기 없는 공개 샘플 | 2~3h |
| P6-1 | 개발일지·ADR·수치 ledger 정리 | P4 | 결과·한계·재현법 1편 | 2~4h |
| P6-2 | 포트폴리오/이력서/README 최신화 | P6-1 | 숫자·모델·기간·역할 정합 | 3~5h |
| P6-3 | 직무군별 제출 메시지 구성 | P6-2 | Python 백엔드/AI 서비스 두 가지 설명 | 2~3h |

표의 시간은 난이도 추정이며 보장되지 않는다. API 대기·quota·환경 문제·라벨 검토에서 추가 시간이 생긴다.

### 현실적인 일정 선택

- **압축 V1: 약 4~6 작업일** — 출제 8개 + Judge 12개 + 장애 replay 8개로 줄이고 파일 보고서·현재 프롬프트 연결·trace 최소 필드에 집중. 연구 수준 유의성 주장은 하지 않음.
- **권장 V1: 약 11~17 작업일** — 위 60개 데이터 준비·gold 검토·검색/라우터·비교 1건·holdout·제출 자료 포함. 티켓 합계 약 65~100시간, 하루 집중 6시간 가정.
- **V1+V2: 약 14~20 작업일** — 읽기 콘솔과 수동 검토·공개 데모 추가. 환경/실API 대기 제외한 추정.
- **공통 문서 파이프라인 확장: 별도 3~5일** — 검토 corpus 준비와 데이터 정제·검색 평가 포함.
- **선택 스택 확장: 각각 별도 2~5일 이상** — 핵심 완료 이후 하나만 선택.

앞서 제안한 2~3일은 기존 스크립트를 최소한으로 묶는 범위에는 가능할 수 있다. gold 검토, Judge 신뢰성, 실행 복구, 비교 UI, 최신 모델 기준선까지 포함한 전체 범위의 일정으로는 과도하게 낙관적이므로 이 계획에서는 수정했다.

## 14. 구현 순서의 분기와 중단 기준

### 우선순위

1. P0 → schema·dataset → path_trace replay/실행 → 비교 보고서.
2. Judge 교정과 검색/라우팅 평가 확장.
3. 결과가 설명 가능하면 포트폴리오 반영 및 지원 시작.
4. 필요하면 V2 콘솔.
5. 여러 공고에 반복되는 문서 처리·Python API·운영 계약을 보강하고 전문 스택은 필요할 때 하나만 선택.

화면 디자인, 대규모 분산 평가, 다른 벡터 DB, 파인튜닝을 동시에 추진하지 않는다. 구현의 선택 기준은 '이 기능이 없으면 실제 변경 판단이나 제출 증거가 불가능한가?'다.

### 중단/보류 조건

- 데이터셋 gold가 모호하면 실험 확대보다 라벨 수정.
- Judge 사람 일치도가 낮으면 종합 점수·자동 승인 보류, 구조/사람 검토만 공개.
- quota 소모가 커지면 Case/반복 축소, 실패 원시 output replay 재사용.
- 변화가 작고 반복마다 뒤집히면 '개선 확인 불가' 판정.
- 결과 콘솔이 core 구현보다 오래 걸리면 Markdown 보고서로 먼저 제출.
- 마감 공고가 있으면 하네스 완료를 지원의 전제조건으로 만들지 않음.

## 15. 포트폴리오·이력서에 어떻게 연결할까

### 포트폴리오 내용 배치

기존 9페이지의 제품·아키텍처·RAG를 유지하되 다음 내용을 전면에 보여준다.

- 평가 페이지: 실제 실패 → Case/gold → 최초 vs 최종 → Judge 한계 → 변경 판단.
- 실행 추적 페이지: 하나의 Case가 검색·라우터·생성·후처리에서 소비한 시간/토큰, 폴백 발생 위치.
- 비교 페이지: baseline/candidate 설정과 실제 회귀 1건 또는 개선 Case, 표본·분모·한계.
- 마지막 증거: 저장소 실행 안내, 공개 JSONL 샘플, CI/replay 보고서, 사람이 내린 결정.

현재 AI 협업 페이지를 전부 삭제할 필요는 없다. 평가 시스템 설명을 우선하고 협업 프로세스는 한 단락으로 압축하거나 부록으로 둔다. 금융 주문 경력과 최신 운영 장애 경험을 첫 인물 소개에 연결한다.

### 숫자 ledger

`claim, value, unit, numerator, denominator, date, model/config, dataset, artifact/commit, limitation`을 한 표로 관리한다.

테스트 개수·문서 수·스크립트 수는 최신 기준일로 수집한다. 표본 단위가 '생성 20회/step 91개'인지 명시한다. 헤드라인·개발 노트·README·이력서·PDF를 같은 ledger로 검토한다.

### 향후 완료 후 쓸 문장 예시

> LLM 출제·검색 파이프라인의 고정 평가셋과 실행 추적을 구축하고, 모델·프롬프트 변경 전후의 오류·재생성·지연·토큰을 비교했습니다. 채점기 오판을 사람 라벨과 대조하고, 실패 원시 응답을 재평가할 수 있도록 보존했습니다.

실제 구현과 검증 후에만 사용한다. 아직 계획 단계인 내용을 이력서 성과로 옮기지 않는다. 좋은 결과 숫자가 없으면 '회귀 발견으로 변경 보류' 사례도 기술 판단의 근거로 쓸 수 있다.

### 면접에서 설명할 네 질문

1. 왜 기존 pytest·healthcheck만으로 품질을 확인할 수 없었나?
2. 왜 index-value 일관성을 사실 정확도와 분리했나?
3. Judge를 어떻게 검증했고 어떤 판정은 사람에게 남겼나?
4. 실제 개선을 위해 바꾼 것과 보류한 것은 무엇이며 어떤 결과 때문인가?

## 16. 잡코리아 공통 요구에서 도출한 추가 보강 방향

2026-10-14 공개 공고 본문 8개와 추가 학력 조건 검토 1개를 확인했다. 특정 회사에 타겟하지 않고 반복되는 역할·스택을 기준으로 계획을 조정했다. 전체 시장 통계가 아닌 목적 표본이며, 조사 범위·출현 매트릭스·지원 조건의 충돌은 [[채용공고 검토 - LearnLog 평가 시스템 보강의 효용 2026-10-14]]에 저장했다.

| 반복 요구 | 핵심 하네스 효용 | 보강 방향 |
| --- | --- | --- |
| Python API·서비스 운영 | 실행·결과·오류·테스트 계약을 보여줌 | DRF API·권한·장기 작업·성능 측정 |
| RAG·검색·문서 처리 | 고정 corpus와 검색/답변 품질 비교 | 소규모 문서 ingest·정제·청킹 우선 |
| 품질 평가·회귀·모니터링 | Case/Run/Result/Trace의 직접 활용처 | 현재 네 항목을 핵심 완료 범위로 유지 |
| Agent workflow·외부 도구 연동 | 도구별 결과·오류도 같은 하네스로 평가 | 읽기 tool 2개, 선택/argument 평가 |
| 로컬 서빙·검색엔진·풀스택 | 기존 평가 기반으로 새 backend 비교 가능 | 전문 확장으로 분류하고 하나만 선택 |

**공통 확장은 문서 파이프라인과 Python API/운영 계약을 우선한다.** 표본 내에서 문서/데이터 전처리·청킹은 4/8, 명시적 AI 품질 평가도 4/8에 나왔다. 이 둘을 연결하는 것이 현재 프로젝트의 다음 단계로 가장 자연스럽다. Local LLM/OpenSearch/React는 각각 다른 역할을 넓히는 선택 역량이다. 아래 A~F는 선택 가능한 모듈 목록이며 모두 구현하는 일정은 아니다.

### A. Local LLM — 로컬 서빙까지 역할을 넓힐 때

- 기존 target/provider 계약을 재사용해 로컬 모델 어댑터 하나 추가.
- 같은 8개 development 입력으로 현재 API 모델과 비교.
- 모델 ID/파일 digest, quantization, 하드웨어/RAM, warm/cold 상태 기록.
- TTFT·출력 속도·JSON 유효성·의미 품질·총 wall time을 비교.
- 로컬 모델을 Judge 정답지로 취급하지 않음.
- 장비에 맞는 크기는 구현 착수 때 확인. 지금 구매/설치하지 않음.
- 공개 claim은 '로컬 서빙과 품질 비교 경험'. 'API 비용 0=총비용 0'이라고 표현하지 않음.

### B. 문서 수집·전처리 — 공통 확장 1순위

- 공식 개발 문서 소규모 묶음을 이용해 문서 ID/version/section/chunk를 관리.
- 청크 크기·제목 포함·중복 제거를 한 변수씩 바꿔 Hit/Recall과 답변 근거를 비교.
- 학습 로그 RAG와 문서 청크 RAG의 corpus와 결과를 분리.
- pandas 경험은 기존 잇다루프의 실제 담당 범위를 먼저 확인해 이력서에 표현. 맡지 않은 팀원 작업을 본인 구현으로 쓰지 않음.
- 평가 결과 JSONL→표 집계에서 pandas를 쓰는 것만으로 데이터 전처리 실무 역량 전체를 충족했다고 주장하지 않음.
- 문서 ID·섹션·버전·청크 ID를 고정하고 중복/누락·encoding·빈 문서 오류를 검사.
- 최초 corpus는 공식 Markdown/HTML 문서 10~20개, 검색 Case 12개를 제안. 입력 수집 권한·원문 라이선스를 확인하고 공개 결과는 필요한 발췌만 보존.
- 본문 정제 방식·청크 정책은 한 변수씩 바꾸고 출처 손실/검색 성공/답변 필수 사실을 함께 비교.
- 완료 기준: 동일 corpus에서 keyword/vector/hybrid 비교 1건, 사용 chunk→답변 근거 추적, 실패 문서/청크 수까지 보고.
- PDF/OCR, GraphRAG, reranking은 이 비교 결과에서 필요성이 확인될 때 확장.

### C. OpenSearch — 검색 시스템 역량을 더 깊게 보일 때

- 현재 PostgreSQL 검색을 유지하고 선택 backend로 소규모 OpenSearch를 비교.
- 동일 corpus·Case·관련성 gold 사용.
- BM25 중심 검색부터 시작하고 필요 시 dense/hybrid 확장.
- 검색 품질·latency·색인 시간·메모리·동기화 부담 비교.
- 기술 채택 결론이 '이 규모에서는 PostgreSQL이 적합'이어도 충분한 실험.
- 단일 노드 로컬 실험을 대규모 분산 운영 경험으로 표현하지 않음.

### D. Tool Calling — Agent 기능으로 확장할 때

- `search_logs` / `get_log_detail`처럼 이미 있는 읽기 기능 두 개를 tool 계약으로 노출.
- 평가셋: 정상 호출, 불필요 호출, 잘못된 argument, 없는 ID, tool 실패.
- 도구 선택·argument schema·결과 해석·실패 회복을 각각 평가.
- 평가 runner가 여러 에이전트를 쓰는 것과 제품이 Agent Tool Calling을 구현한 것을 구분.
- DB 쓰기·임의 쉘·메시지 발송 tool은 필요 없음.

### E. 비동기 실행·권한 — 공통 Python 백엔드 확장

- 먼저 CLI 결과 조회를 완성한 후 필요 시 job 생성·상태 조회 API.
- pending/running/succeeded/failed/cancelled 계약, 중복 요청 키, staff 권한, timeout·재개.
- durable worker 필요성이 확인되면 큐 도입 비교. 데몬 스레드만으로 작업 완료 보장 주장 금지.
- 빠른 API와 긴 작업 분리의 실제 효과를 작은 부하 실험으로 측정.
- 가상 입력의 테스트 부하와 실제 사용자 트래픽을 구분해 표기.
- FastAPI는 표본에서 유사 프레임워크 예시/업무 환경으로 등장했다. Django를 교체하지 않고 필요 시 동일 runner를 연결하는 작은 adapter로 경험 범위를 넓힌다.
- 인증은 기존 Django staff 권한으로 시작하고 API 요청 ID·오류 schema·페이지네이션·작업 상태 계약을 먼저 확정한다.
- 완료 기준: 무권한 접근 차단, 중복 job 방지, 긴 평가 중 조회 요청 유지, 실패/취소/재개 상태의 일관성 검증.

### F. React/TypeScript — 풀스택까지 지원 범위를 넓힐 때

- 이미 React 경험이 있는지 먼저 확인.
- 부족하면 전체 LearnLog UI를 재작성하지 않고 평가 비교/Case 상세 한 화면 구현.
- 기존 Django API의 페이지네이션·오류 상태·권한·SSE를 연결.
- 프런트 UI 완성도가 이번 하네스의 평가 설계를 대신하지 않도록 작업량 제한.

## 17. 설계 결정 기록 (ADR 초안)

| 결정 | 선택 | 이유/다시 검토할 조건 |
| --- | --- | --- |
| 최초 저장 | JSONL + manifest | 기존 자산 재사용·빠른 재분석; 다중 writer가 필요하면 DB |
| 결과 콘솔 | Django/HTMX 읽기 중심 | 현재 스택 재사용; 풀스택 경험을 넓힐 때 React 별도 화면 |
| 평가 실행 | CLI 별도 프로세스 | 긴 작업이 웹 워커·SSE 연결을 점유하지 않음 |
| 품질 기준 | 구조/의미/운영 분리 | 한 점수로 다른 결함을 상쇄하지 않음 |
| Judge 근거 | 사람 라벨·공식 근거 | 다른 LLM 합의를 정답지로 취급하지 않음 |
| 현행 프롬프트 | 공통 builder | 실제로 drift 사고가 있었으므로 주석 동기화에서 발전 |
| 과거 프롬프트 | frozen snapshot | 과거 결과의 재분석 가능성 유지 |
| 운영 컨텍스트 | 실제 입력 snapshot | 현재 DB reference에서 역복원하면 순서·내용이 달라질 수 있음 |
| CI | replay와 live 검사를 분리 | 외부 quota/장애와 코드 회귀를 구분 |
| 정책 자동 승인 | 초기 보류 | 소표본·Judge 불확실성을 사람이 검토 |

## 18. 최종 완료 체크리스트

- [ ] 현재 모델·설정·사용량·검사 범위를 기준선으로 고정했다.
- [ ] reviewed dataset과 development/holdout을 버전 관리한다.
- [ ] 현재 프로덕션 prompt를 복사본 없이 평가에 사용한다.
- [ ] 기존 원시 JSONL을 provenance와 함께 import/replay할 수 있다.
- [ ] 최초·재생성·탈락·최종 출력과 API 실패를 모두 보존한다.
- [ ] 품질·오류·coverage·제공 가능률의 분모가 보고서에 표시된다.
- [ ] TTFT·wall time·입출력/추론 토큰·폴백·재시도를 추적한다.
- [ ] Judge 오탐/누락을 사람 라벨로 확인했다.
- [ ] 생성에 사용된 실제 컨텍스트와 검증에 제공된 컨텍스트가 추적된다.
- [ ] baseline/candidate 1개 비교와 채택/보류 이유를 남겼다.
- [ ] 중단/재개·재채점·중복 저장·silent pass를 검증했다.
- [ ] 평가 실행이 학습 DB/Streak/일지를 오염시키지 않는다.
- [ ] 외부 API 가용성과 코드 CI와 품질 평가의 책임을 구분했다.
- [ ] 공개 sample로 결과 집계를 재현할 수 있다.
- [ ] 이력서·포트폴리오·README의 모델·수치·기간이 일치한다.
- [ ] 여러 공고의 공통 요구에 따라 문서 처리·API/운영을 우선하고 전문 확장은 하나씩 선택했다.

## 부록 A. 기존 35편 전체의 활용 위치

문서의 과거 코드 예시를 최신 구현으로 단정하지 않고, 현재 코드와 대조해 결정의 맥락으로 사용했다. 첨부 이미지·영상 전체를 별도 시각 검수한 것은 아니다.

| 문서 | 이번 계획에 반영한 내용 |
| --- | --- |
| [[Django 모델 설계 및 마이그레이션 초기화]] | 평가 기록 별도 책임·기존 학습 데이터 보존 |
| [[GitHub Actions로 테스트자동화]] | 결정적 CI와 실API 평가의 구분 |
| [[Gunicorn 워커 타임아웃 트러블슈팅 - 스트리밍 응답 SIGKILL]] | 긴 평가를 웹 요청 밖에서 실행 |
| [[LLM 공급자 하이브리드 전환 - Groq + Mistral 속도·품질 벤치마크]] | 작업별 모델·historical 성능 구분 |
| [[LLM 응답 속도 최적화 - 병렬화, 프롬프트 경량화, 스트리밍]] | 병렬 span·실제 출력·TTFT 계측 |
| [[LLM 추론에서 입력은 싸고 출력이 비싸다]] | input/output/reasoning·범위 제한 |
| [[LangGraph 라우팅 에이전트 - 질문별 조건 분기]] | 현재 graph target·웹 생략 경로 평가 |
| [[LearningLog 모델 필드 설계]] | snapshot과 operational FK 분리 |
| [[PostgreSQL 버전 불일치 트러블슈팅 - dbpull 실패]] | DB/client/runtime 버전 manifest·환경 확인 |
| [[Quartz로 Obsidian 볼트 웹 배포하기]] | 최종 공개 자료·링크 검증·수동 동기화 단계 |
| [[RAG 검색 파이프라인 개선 — 한국어 질문이 엉뚱한 결과를 부르던 문제]] | rewrite/domain/version Case |
| [[Render 무료 배포 + DB 동기화 + 자동 백업 구현]] | 결과 export/백업·운영 DB 격리 |
| [[SSE 진행 스트리밍 - 프로그레스바·진행로그]] | 첫 답변/완료 이벤트·stream 실패 회귀 |
| [[correct_index 런타임 가드 — 정답 인덱스 정합성 검증]] | 내부 정합 vs 의미·원시/최종 분모 |
| [[log list API 테스트 작성]] | factory/DB 격리·조회 테스트 재사용 |
| [[pgvector 하이브리드 RAG - FTS+벡터 RRF 결합]] | 고정 corpus·Hit/Recall·검색 실험 |
| [[render 배포웹 슬립 방지]] | cold/warm 분리·historical 제약 재확인 |
| [[vscode에서 Docker 컨테이너 디버깅하기]] | 실행 환경 재현·별도 runner 디버깅 |
| [[간격 반복 연습문제 - 자동 출제·채점]] | input log·step·attempt 단위 구분 |
| [[검색 도메인 자동 매핑 - 출처 판단 개선]] | domain correctness·substring fixture |
| [[꼬리질문 - self-FK 질문 트리 구현]] | 부모/루트 snapshot·fixture 누설 방지 |
| [[멀티에이전트 작업을 기록으로 남기기 - 진행판과 Codex 브릿지 인계]] | requested/confirmed 모델 구분·변경불가 snapshot·판단 이력 |
| [[메타인지 학습 UX 재설계 - 안 쓰는 기능을 다시 만들기]] | 자가채점과 시스템 품질 평가 분리 |
| [[선택지 문제 품질 게이트 - 멀티에이전트로 설계 검토하기]] | raw/drop/soft·오탐·교정 실험·소표본 선택률 한계 |
| [[싱글턴 패턴 - Streak 모델 적용]] | 평가가 singleton 학습 상태를 건드리지 않음 |
| [[쓰던 모델 4개가 한꺼번에 죽었다 - 교체와 CI가 못 잡은 이유]] | 최신 모델·가용성·빈 출력·prompt drift |
| [[일일 학습일지]] | 평가 출력 저장 시 자동 부수효과 방지 |
| [[코드 청소 - 중복·죽은 경로·조용히 저장되던 버그]] | 공통 컨텍스트·오류 저장 방지·좁은 patch |
| [[통계 대시보드 + Streak(불꽃) 시스템 구현]] | 서비스 효과와 평가 품질 지표 구분 |
| [[프롬프트 검증 재설계 - pytest를 버리고 실험 스크립트로]] | 예산·반복·재분석·채점기 검증 |
| [[프롬프트 변경 효과 측정 - correct_index 오류율 비교 테스트]] | historical 비교·8/80·4/80·미판정 정의 |
| [[학습 로그 서비스 계층 설계 및 구현]] | 서비스 target 어댑터·save 경계 |
| [[학습로그 검색 기능 - Full-Text Search 구현]] | 키워드 baseline·개인 corpus 규모 제한 |
| [[환각 방어 - 예방·검출·표시 3단]] | 사실/모순/근거부족 분리·Judge calibration |
| [[📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템]] | 제출 메시지·stale 모델/숫자 ledger |

## 부록 B. 외부 참고

제안의 구현 세부는 현재 저장소와 개발문서에서 도출했다. 평가 개념의 확인에는 아래 공식 자료를 참고했다.

- [LangSmith 평가 유형](https://docs.langchain.com/langsmith/evaluation-types): offline/online·code/Judge·회귀 평가 구분. 이 계획은 외부 플랫폼 도입을 전제하지 않는다.
- [LangSmith evaluate reference](https://reference.langchain.com/python/langsmith/client/Client/evaluate): dataset·실험·반복 실행 개념 참고.
- [Django management command](https://docs.djangoproject.com/en/5.2/howto/custom-management-commands/): 기존 Django 환경에 CLI entrypoint를 추가하는 방식 참고. 실제 설치 버전과 맞는 문서를 구현 시 다시 확인.
- [Groq 공식 문서](https://console.groq.com/docs/openai): provider 지원 옵션은 동일 API 형식이어도 차이가 있으므로 adapter별 확인.

문서·quota·모델 alias는 변경될 수 있다. manifest에 구현 시 확인한 조건을 남기고, 과거 외부 서비스 설명을 현재 계약처럼 사용하지 않는다.

## 부록 C. 변경 채택 기준과 실제 보고서 형태

### 시스템 완료 조건과 모델 성능 목표는 구분한다

하네스 자체의 계약은 결정적으로 확인한다. 원시 결과 보존 누락·실패를 통과로 집계·학습 DB 오염·다른 dataset의 직접 비교는 0건이어야 한다. 재시도·중단·폴백 fixture가 통과해야 한다.

모델 품질은 실제 baseline을 잰 뒤 기준을 고정한다. 지금 정확도 95%·지연 3초처럼 근거 없는 수치를 먼저 성공 조건으로 쓰지 않는다.

초기 변경 채택 규칙은 다음으로 제안한다.

| 기준 | 초기 정책 |
| --- | --- |
| critical Case 회귀 | 새 회귀가 관찰되면 자동 채택 금지, 사람 검토 |
| 실행/평가 미완료 | coverage·실패를 명시, 평가 완료로 표시 금지 |
| 구조 정합 개선 | 최종 yield와 재생성/토큰 비용도 함께 검토 |
| 의미 품질 개선 | reviewed gold/사람 판정에 근거, Judge 점수 단독 채택 금지 |
| latency 개선 | 같은 조건의 wall time/TTFT를 비교, 잘림·내용 누락이 늘면 개선으로 채택하지 않음 |
| 작은 변화 | 반복 결과가 뒤집히면 판단 보류, 표본 확대 또는 현행 유지 |
| Judge 교체 | 모순 누락·무관 오탐·미판정·비용을 함께 보고 development에서 선택한 뒤 holdout 확인 |

품질이 동등하고 지연·호출량이 줄었다면 운영 개선으로 채택할 수 있다. 품질이 개선돼도 비용 증가가 목적에 비해 크면 보류할 수 있다. trade-off는 가설·정책 결정 기록에 남긴다.

### 보고서에서 실제로 볼 항목

보고서의 첫 문장은 '어떤 실패를 줄이려고 무엇 하나를 바꿨는지'다. 이어서 다음 순서로 표시한다.

1. 실행/평가 상태: 계획 수·완료 수·실패 수·미판정 수, dataset/모델/프롬프트/evaluator 버전.
2. 비교 설정: 어떤 변수가 달라졌고 무엇을 고정했는지, fixed/live 범위.
3. 결과 표: 정확한 분자/분모, case macro 지표, 첫 생성·최종/yield, TTFT·wall time·토큰.
4. 회귀 목록: 입력·근거·이전 출력·새 출력·평가 사유.
5. 대표 개선/보류 Case: 원시 payload와 trace로 이어지는 링크.
6. 한계: 표본·holdout·Judge coverage·provider 변동·실패 누락 가능성.
7. 결정: 채택/보류/기각, 근거, 후속 실험 하나.

### 실제 작업 착수 시 첫 세 티켓

- **첫 티켓**: 현행 서비스·과거 JSONL의 기준선 목록, manifest/schema 예시, public/private artifact 정책을 정한다. 코드를 크게 재편하기 전에 원시 필드와 수치 단위를 확인한다.
- **둘째 티켓**: 대표 Case 8~12개를 사람 검토하고 replay runner를 만든다. 저장·재채점·실패 집계가 동작할 때까지 API 호출을 최소화한다.
- **셋째 티켓**: 현행 출제 prompt builder와 raw/audit recorder를 연결하고 5개 smoke를 실행한다. 생존율/최초·최종 출력/재생성/토큰이 모두 보이면 Judge와 검색으로 확장한다.

이 세 티켓의 산출물로 구현 방향을 재검토할 수 있다. 후속 구현 요청에서는 이 계획의 제안 전체를 한 번에 완료하는 대신 V1의 완료 조건부터 순서대로 진행한다.
