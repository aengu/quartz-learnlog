# 📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템

[https://github.com/aengu/learn-log](https://github.com/aengu/learn-log)

[Learn Log - AI 개발 지식 베이스](https://learn-log.onrender.com/)

## 🎯 프로젝트 개요

개발 질문을 기록하고, 그 내용으로 만든 문제를 풀며 복습하는 개인 AI 학습 서비스입니다.

1. **질문한다:** “DB 잠금이 뭐야?”처럼 궁금한 내용을 묻고 답변을 저장합니다.
2. **문제를 푼다:** 저장한 답변을 바탕으로 생성된 연습문제로 복습합니다.
3. **결과를 확인한다:** 러닝메이트와 정오답을 비교하고, 내 개념별 이해도 변화를 살펴봅니다.

**AI 러닝메이트**는 내 학습 수준에 맞춰 같은 문제를 푸는 AI 파트너입니다. 함께 문제를 풀고 결과를 비교해 학습 동기를 높이는 것을 목표로 합니다. 내 이해도는 별도로 BKT(정오답으로 개념을 알고 있을 확률을 갱신하는 모델)로 추정합니다.

저장한 기록은 이후 질문의 답변 생성에도 재활용합니다. 하이브리드 검색(RAG)은 기록 재활용을, BKT는 개념별 학습 상태 확인과 러닝메이트 수준 조정을 위해 선택했습니다.

> 개발하면서 직접 사용하는 개인 학습 도구입니다. 사용 중 느낀 불편을 기능 개선으로 이어가며, 성능·출력 정합성은 벤치마크로, 코드 동작은 테스트와 정적 검사로 확인합니다. BKT 숙련도는 고정 가정값 기반의 초기 추정이며, 학습 효과 검증과는 구분합니다.

<img src="LearnLog/attachments/Learn-Log---AI-개발-지식-베이스.gif" width="720" alt="LearnLog 실행 화면" />

<div class="ll-stats">
  <div class="ll-stat"><b>진행 중</b><span>지속 개선 (2026.1–현재)</span></div>
  <div class="ll-stat"><b>개념별 이해도</b><span>BKT 추정 · 러닝메이트 수준 연동</span></div>
  <div class="ll-stat"><b>52.6→37.3s</b><span>생성 시간 비교 · 당시 Mistral</span></div>
  <div class="ll-stat"><b>20%→84%</b><span>당시 연습문제 서비스 커버리지</span></div>
</div>

---

## 🏗 아키텍처

### 서비스 처리 흐름

<div class="rs-flow">
<svg class="flow" viewBox="0 0 1600 460" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="질문 흐름: 질문 입력, 관련 기록 검색, 라우터의 검색·답변 방식 결정, AI 답변 생성, 학습 기록 저장. 복습 흐름: 문제 생성·태깅, 나와 AI 러닝메이트의 문제 풀이, 개념별 이해도 갱신(BKT), 결과 확인. 두 흐름은 서로 다른 시점에 실행합니다.">
<rect width="1600" height="460" rx="16" fill="#F5F5F5"/>
<text x="40" y="42" fill="#315EAE" style="fill:#315EAE" text-anchor="start" font-family="Inter, Pretendard, Arial, sans-serif" font-size="27" font-weight="700">질문할 때</text>
<rect x="40" y="70" width="280" height="94" rx="12" fill="#EAF1FF" stroke="#315EAE"/>
<text x="180" y="126" fill="#315EAE" style="fill:#315EAE" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">질문 입력</text>
<path d="M 320 117 H 350 M 339 111 L 350 117 L 339 123" fill="none" stroke="#315EAE" stroke-width="2"/>
<rect x="350" y="70" width="280" height="94" rx="12" fill="#EAF1FF" stroke="#315EAE"/>
<text x="490" y="126" fill="#315EAE" style="fill:#315EAE" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">관련 기록 검색</text>
<path d="M 630 117 H 660 M 649 111 L 660 117 L 649 123" fill="none" stroke="#315EAE" stroke-width="2"/>
<rect x="660" y="70" width="280" height="94" rx="12" fill="#EAF1FF" stroke="#315EAE"/>
<text x="800" y="111" fill="#315EAE" style="fill:#315EAE" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">검색·답변 방식 결정</text>
<text x="800" y="142" fill="#315EAE" style="fill:#315EAE" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">(라우터)</text>
<path d="M 940 117 H 970 M 959 111 L 970 117 L 959 123" fill="none" stroke="#315EAE" stroke-width="2"/>
<rect x="970" y="70" width="280" height="94" rx="12" fill="#101828" stroke="#FFFFFF"/>
<text x="1110" y="126" fill="#FFFFFF" style="fill:#FFFFFF" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">AI 답변 생성</text>
<path d="M 1250 117 H 1280 M 1269 111 L 1280 117 L 1269 123" fill="none" stroke="#315EAE" stroke-width="2"/>
<rect x="1280" y="70" width="280" height="94" rx="12" fill="#EAF1FF" stroke="#315EAE"/>
<text x="1420" y="126" fill="#315EAE" style="fill:#315EAE" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">학습 기록 저장</text>
<text x="40" y="202" fill="#667085" style="fill:#667085" text-anchor="start" font-family="Inter, Pretendard, Arial, sans-serif" font-size="21">라우터가 기록·웹 자료 사용 여부와 설명 방식을 결정하고, 답변은 스트리밍으로 전달합니다.</text>
<path d="M 40 229 H 1560" stroke="#D0D5DD" fill="none"/>
<text x="40" y="273" fill="#6941C6" style="fill:#6941C6" text-anchor="start" font-family="Inter, Pretendard, Arial, sans-serif" font-size="27" font-weight="700">복습할 때</text>
<rect x="40" y="300" width="290" height="94" rx="12" fill="#F0EAFF" stroke="#6941C6"/>
<text x="185" y="356" fill="#6941C6" style="fill:#6941C6" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">문제 생성·태깅</text>
<path d="M 330 347 H 450 M 439 341 L 450 347 L 439 353" fill="none" stroke="#6941C6" stroke-width="2"/>
<rect x="450" y="300" width="290" height="94" rx="12" fill="#F0EAFF" stroke="#6941C6"/>
<text x="595" y="341" fill="#6941C6" style="fill:#6941C6" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">문제 풀이</text>
<text x="595" y="372" fill="#6941C6" style="fill:#6941C6" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">나 · AI 러닝메이트</text>
<path d="M 740 347 H 860 M 849 341 L 860 347 L 849 353" fill="none" stroke="#6941C6" stroke-width="2"/>
<rect x="860" y="300" width="290" height="94" rx="12" fill="#E7F8F1" stroke="#087A5B"/>
<text x="1005" y="341" fill="#087A5B" style="fill:#087A5B" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">개념별 이해도 갱신</text>
<text x="1005" y="372" fill="#087A5B" style="fill:#087A5B" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">(BKT)</text>
<path d="M 1150 347 H 1270 M 1259 341 L 1270 347 L 1259 353" fill="none" stroke="#6941C6" stroke-width="2"/>
<rect x="1270" y="300" width="290" height="94" rx="12" fill="#F0EAFF" stroke="#6941C6"/>
<text x="1415" y="341" fill="#6941C6" style="fill:#6941C6" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">결과 확인</text>
<text x="1415" y="372" fill="#6941C6" style="fill:#6941C6" text-anchor="middle" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23" font-weight="700">정오답 · 내 이해도</text>
<text x="40" y="436" fill="#667085" style="fill:#667085" text-anchor="start" font-family="Inter, Pretendard, Arial, sans-serif" font-size="21">검토·승인된 문항의 사용자 풀이만 BKT에 반영합니다.</text>
</svg>
</div>

학습기록을 먼저 검색하고, 그 결과를 본 라우터가 기록 활용 여부와 웹검색 필요 여부를 판단합니다. 생성한 답변은 사용자에게 스트리밍하며, 저장 후 모순 검사는 백그라운드에서 실행합니다. 저장된 기록은 다음 질문의 검색에 재활용합니다.

*구현: 파이프라인 LangGraph · 검색 pgvector+FTS · 답변·검사 Groq의 서로 다른 모델 · 임베딩 Mistral · 웹검색 Tavily*

### 복습 반영 기준

저장한 답변으로 문제와 개념 후보를 생성하며, 문항·개념 연결 검토와 승인·보류는 수동으로 관리합니다. 승인된 문항의 사용자 정오답으로 BKT 현재 상태와 변화 이력을 갱신합니다.

러닝메이트는 자신의 풀이 시작 시점 이전 사용자 기록으로 수준을 맞춥니다. 이번 사용자 답을 미리 참고하지 않으며, 러닝메이트의 정오답은 사용자 BKT에 반영하지 않습니다.

---

## 주요 기술적 도전

<table class="ll-table">
<thead><tr><th>도전</th><th>문제 → 접근</th><th>결과</th></tr></thead>
<tbody>
<tr>
<td>📚 <b>학습기록 재활용 (RAG)</b><small>FTS + 벡터 하이브리드 검색</small></td>
<td>쌓인 학습기록이 답변 생성에 쓰이지 않았고, 키워드 검색(FTS)은 "N+1 문제"를 "ORM 쿼리 반복 호출"이라는 질문으로 못 찾는다. pgvector 의미 검색을 FTS와 RRF로 결합해 top-3을 프롬프트에 주입 — 전용 벡터 DB 없이 PostgreSQL 확장 하나로.</td>
<td><span class="ll-num">추가 지연 0.65s · 2%</span><a href="../LearnLog/pgvector-하이브리드-RAG---FTS+벡터-RRF-결합">상세 →</a></td>
</tr>
<tr>
<td>🛡 <b>환각 방어</b><small>예방 · 검출 · 표시 3단</small></td>
<td>잘못된 답변이 다음 답변과 복습 문제에 재사용될 수 있어, 공식 문서 검색을 통한 생성 근거 확보·생성과 <b>다른 모델</b>의 저장 후 모순 검사·검사 상태와 의심 사유 표시로 관리했습니다. 문제 생성 시에도 의심 기록을 경고합니다. 검사 모델의 판정 66건을 Claude로 교차확인했으며, 근거 자체의 진위나 모든 환각을 검증하는 것은 아닙니다.</td>
<td><span class="ll-num">응답 안 막는 검증</span><a href="../LearnLog/환각-방어---예방·검출·표시-3단">상세 →</a></td>
</tr>
<tr>
<td>⚡ <b>답변 처리 시간 개선</b><small>후처리 병렬화 · 프롬프트 경량화 · SSE</small></td>
<td>독립적인 태그·마크다운 후처리를 병렬화해 2.89s→1.01s로 단축했습니다. 프롬프트 경량화 전후 생성 시간 약 29% 감소를 관측했으며, 출력 길이 영향과는 분리하지 못했습니다. SSE는 완료 시간 단축과 별개로 생성 중 답변을 전달합니다.</td>
<td><span class="ll-num">답변 생성 52.6s→37.3s</span><small>당시 Mistral Large<br/>단일 질문 · 2라운드 평균<br/>52.56s → 37.32s (약 29% 단축)<br/>전체 요청 시간과는 별도 측정</small><a href="../LearnLog/LLM-응답-속도-최적화---병렬화,-프롬프트-경량화,-스트리밍">상세 →</a></td>
</tr>
<tr>
<td><b>테스트 공백과 CI 품질 검사</b><small>핵심 로직 보강 · 검사 결과 가시화</small></td>
<td>테스트 개수만으로 검증 범위를 알 수 없어 분기 커버리지를 측정하고, 출제·채점·복습의 공백을 보강했습니다. Ruff 정적 검사와 커버리지 Summary/PR 리포트를 CI에 연결하고, 실제 외부 API 상태는 예약 헬스체크로 분리했습니다.</td>
<td><span class="ll-num">서비스 커버리지 20%→84%</span><small>당시 연습문제 서비스 기준<br/>현재 일반 테스트 230개 통과<br/>전체 커버리지 수치와 구분</small><a href="../LearnLog/연습문제-서비스-테스트-보강---커버리지-20-percent--%3E84-percent">테스트 보강 →</a><a href="../LearnLog/테스트-커버리지와-Ruff-정적-분석---CI-코드-품질-자동화">CI 품질 검사 →</a></td>
</tr>
<tr>
<td><b>개념별 숙련도 추적</b><small>고정 파라미터 BKT · 러닝메이트 연동</small></td>
<td>최근·유사 문제 점수만으로는 개념별 강약점을 구분하기 어려워, 수동 승인한 문항의 정오답으로 숙련도를 갱신했습니다. 현재 상태와 관측 이력을 분리하고 중복 반영 방지·시간순 재계산을 구현해 러닝메이트 정답 확률과 통계 그래프에 연결했습니다.</td>
<td><span class="ll-num">풀이별 상태 추정·변화 추적</span><small>단일 사용자 MVP<br/>파라미터 학습·망각은 미반영<br/>추정 정확도·학습 효과는 미검증</small><a href="../LearnLog/BKT로-개념별-숙련도-추적하기---러닝메이트-수준-맞추기">상세 →</a></td>
</tr>
</tbody>
</table>

<details>
<summary>추가 검증 사례: 채점기 오판 수정 · 정답 인덱스 검증</summary>

### 채점 스크립트의 오판 발견·교체

프롬프트 변경 효과를 측정하던 중 원시 응답을 확인해, 오류로 분류한 결과의 75%가 채점 스크립트의 오판임을 발견했습니다. 채점기를 수정하고 스킵률 90%인 정규식 채점을 다른 모델의 LLM 교차 채점으로 교체했습니다. 비교 문항 80개에서 Judge의 오류 판정은 8건에서 4건으로 줄었으며 모호한 판정도 포함합니다.

→ [[프롬프트 검증 재설계 - pytest를 버리고 실험 스크립트로|채점기 개선 상세]]

### 정답 값·선택지 위치의 일관성 검사

정답 값과 선택지 위치의 불일치를 코드로 검사하고, 불일치 문항 제외·실패 시 재생성을 구현했습니다. 적용 후 20회 생성한 최종 문항 91개에서 불일치 0건을 관측했습니다. 해당 실행에서 재생성은 발생하지 않았으므로 가드의 제거 효과를 입증한 것은 아닙니다. 두 필드가 같은 오답을 가리키면 통과할 수 있어 사실 정확도와도 구분합니다.

→ [[correct_index 런타임 가드 — 정답 인덱스 정합성 검증|정답 인덱스 검증 상세]]

</details>

---

## ✨ 주요 기능

### AI 답변 + 공식 레퍼런스 정리
필요할 때 Tavily로 웹 자료를 검색하고, Groq의 생성 모델로 답변을 스트리밍한 뒤 마크다운으로 정리합니다. 출처를 함께 보관하되, 검색된 자료가 답변의 모든 주장을 보증하는 것은 아닙니다. *(위 실행 화면)*

### 과거 학습기록 재활용 (RAG)
저장·태그 분류된 학습기록을 키워드 + 의미(pgvector)로 검색해 답변 컨텍스트에 주입합니다. "N+1 문제"로 저장한 기록을 "ORM이 반복 호출돼 느린 문제" 질문으로 찾아옵니다 — 키워드가 안 겹쳐도.

### 질문별 경로 라우팅
라우터가 **웹검색 필요 여부·학습기록 사용 여부**와 함께 **설명 초점·예제 스택(SQL/Python/Django/auto)**을 선택합니다. SQL로 충분한 질문에 Django 예제를 억지로 붙이지 않도록 생성 지침을 분기하며, 기존 스트리밍은 유지합니다.

### 환각 방어
생성 모델과 다른 LLM이 답변과 생성 근거의 모순을 **저장 후 비동기** 검사합니다. 검사 상태·의심 사유를 표시하고, 해당 기록으로 문제를 만들 때 경고합니다. 검사는 스트리밍 응답과 분리했으며, 이미 전달한 답변을 자동 수정하거나 모든 주장의 사실성을 보장하지는 않습니다.

### 간격 반복 연습문제
저장한 기록을 바탕으로 선택지 고르기·직접 답하기 두 유형을 출제하고, 1·3·7·14·30일 간격으로 복습을 관리합니다. 새 선택지 문항에는 개념·사고 유형·추정 난이도를 태깅하며, 새 개념 후보는 검토 후 등록합니다. 태그 형식 검증과 문항의 사실성 검토는 구분합니다.

<div class="ll-shots">
<img src="LearnLog/attachments/quiz-choice.png" alt="선택지 고르기 — 단계별 경로 추적" />
<img src="LearnLog/attachments/quiz-write.png" alt="직접 답하기 — 자가채점 + 모범답안 + AI 피드백" />
</div>

### 개념별 숙련도 + AI 러닝메이트
승인된 선택지 문항의 정오답을 기본 BKT에 반영해 개념별 숙련도와 풀이 전후 이력을 저장합니다. 러닝메이트는 같은 문제를 풀되, 사용자 숙련도로 예상 정답 확률을 보정합니다. 이번 사용자 답을 미리 참고하지 않도록 풀이 시작 시점 이전 기록만 사용하며, 미승인 문항에는 기존 수준 추정을 유지합니다.

숙련도는 초기값·실수율·추측률·학습 전이율을 고정한 추정치입니다. 러닝메이트 자신의 독립 성장과 파라미터 학습은 아직 구현하지 않았습니다.

### 통계 대시보드 + Streak
학습량·정답률·연속 학습일수(Streak)를 잔디 스타일로 시각화합니다. 개념별 현재 숙련도·예상 정답률·관측 수를 비교하고, 그래프의 점을 선택해 당시 정오답·숙련도 변화·파라미터를 확인합니다. 기록 없는 개념은 0%가 아닌 ‘관측 없음’으로 표시합니다.

<img class="ll-shot" src="LearnLog/attachments/dashboard.png" width="600" alt="통계 대시보드" />

<img class="ll-shot" src="LearnLog/attachments/bkt-20261030-02-correct-mastery-and-parameters.png" width="720" alt="개념별 숙련도 변화 그래프와 당시 파라미터" />

### 테스트·정적 검사·외부 API 모니터링
GitHub Actions에서 Ruff → pytest·분기 커버리지 측정 → Job Summary/PR 리포트를 자동화했습니다. Ruff는 우선 F 규칙부터 적용하고, 커버리지는 일괄 실패 기준보다 측정과 핵심 로직 보강부터 시작했습니다. 일반 테스트는 외부 호출을 대체하고, 실제 Groq·Mistral·Tavily 응답은 별도 예약 헬스체크로 확인합니다. PR에는 CodeRabbit을 보조 리뷰로 추가하되, 지적은 코드와 테스트 범위를 확인해 판단합니다.

### 개발·운영 방식

Claude Agent Teams로 설계 쟁점을 검토하고, 변경 코드와 논의 맥락을 Codex에 전달해 테스트와 함께 교차 검증했습니다. AI의 제안과 CodeRabbit 리뷰는 근거를 확인해 수용 여부를 직접 판단합니다.

Docker Compose·Render로 배포하고, 로컬·배포 DB 동기화 커맨드와 GitHub Actions 주간 자동 백업을 구현했습니다. 개발 기록은 아래 타임라인에서 확인할 수 있습니다.

## 🛠 기술 스택

- **Backend**: Django 5 · DRF · **PostgreSQL 18** — FTS + pgvector 하이브리드 검색을 별도 벡터 DB 없이 DB 안에서 해결
- **AI 파이프라인**: LangGraph — 검색 경로·설명 초점·예제 스택 라우팅, Groq 생성·경량 판단 + Mistral 임베딩
- **숙련도 추적**: 기본 BKT 수식 직접 구현 — 고정 파라미터 상태 추정, PostgreSQL 상태·관측 이력 저장 (pyBKT 패키지 미사용)
- **Frontend**: Django Template + **HTMX** — SPA 없이 SSE 스트리밍·무한스크롤·부분 갱신 · Tailwind CSS
- **Testing & CI**: pytest · factory_boy (일반 테스트 230개 통과) · pytest-cov · Ruff · GitHub Actions push/PR 검사·예약 API 헬스체크, CodeRabbit PR 리뷰
- **Deployment**: Docker Compose · Render (Web Service + Managed PostgreSQL)

---

## 🤖 LLM·검색 API

작업 성격에 맞춰 3개 API를 분리해서 씁니다.

- **Tavily** — 공식 문서 웹 검색·발췌 (RAG의 웹 소스)
- **Groq / openai/gpt-oss-120b** — 답변·문제 생성과 마크다운 변환
- **Groq / qwen/qwen3.8-27b** — 라우팅·태그·모순 검사·러닝메이트 선택지 판단 등
- **Mistral / mistral-embed** — 학습 로그의 1,024차원 임베딩

> 위 모델명은 현재 코드 설정 기준입니다. 과거 Mistral Large 기반 성능 측정과 공급자 전환 기록은 별도 문서에 남겼습니다. → [[LLM 공급자 하이브리드 전환 - Groq + Mistral 속도·품질 벤치마크|과거 벤치마크]] · [[쓰던 모델 4개가 한꺼번에 죽었다 - 교체와 CI가 못 잡은 이유|모델 교체와 헬스체크 도입]]

---

## 개발 후기

**왜 만들었나** — 검색해서 저장만 하고 다시 안 보는 문제가 있었습니다. 그 순간엔 이해한 것 같은데 며칠 뒤 같은 걸 또 검색하고 있었어요. "검색 → 정리 → 복습"이 한 곳에서 도는 시스템이 필요했습니다.

**실제로 쓰나** — 직접 사용하면서, 초기에는 연습문제 정답률 40%를 보고 저장만으로는 복습이 충분하지 않다는 점을 느꼈습니다. 지금은 전체 점수에 더해 개념별 숙련도 변화도 확인할 수 있게 확장했습니다. 정답률과 숙련도 추정이 실제 이해도를 그대로 뜻하는 것은 아닙니다.

**아쉬운 점** — 생성 문항의 정답 오류·조건의 모호함을 형식 검사만으로 해결할 수 없어, BKT 반영 전 문항 검토는 수동으로 유지합니다. 숙련도 역시 고정 가정값 기반이라 데이터가 쌓인 뒤 예측을 검증해야 합니다. 외부 모델의 응답 속도·정책 변경에 대한 의존성도 남아 있습니다.

---

## 개발 타임라인

2026년 1월부터 38편 — 검색 아카이브에서 RAG·환각 방어, 테스트·CI 품질 검사, BKT 숙련도 추적과 러닝메이트 연동까지 기록했습니다. 태그를 누르면 영역별로 필터됩니다.

성공만 기록하지 않았습니다 —

<div class="ll-proof">
<a href="../LearnLog/LLM-응답-속도-최적화---병렬화,-프롬프트-경량화,-스트리밍">🧪 효과 없던 실험도 기록 (max_tokens)</a>
<a href="../LearnLog/LLM-응답-속도-최적화---병렬화,-프롬프트-경량화,-스트리밍">✏️ 틀린 결론을 두 달 뒤 실험으로 정정</a>
<a href="../LearnLog/correct_index-런타임-가드-—-정답-인덱스-정합성-검증">⚠️ 시스템이 못 잡는 유형까지 문서화</a>
</div>

<div class="ll-tl">
<input type="radio" name="llf" id="f-all" checked>
<input type="radio" name="llf" id="f-design">
<input type="radio" name="llf" id="f-feature">
<input type="radio" name="llf" id="f-rag">
<input type="radio" name="llf" id="f-verify">
<input type="radio" name="llf" id="f-perf">
<input type="radio" name="llf" id="f-test">
<input type="radio" name="llf" id="f-ops">
<input type="radio" name="llf" id="f-cs">
<div class="ll-filter"><label for="f-all">전체</label><label for="f-design">설계</label><label for="f-feature">기능구현</label><label for="f-rag">AI/RAG</label><label for="f-verify">AI/검증</label><label for="f-perf">성능</label><label for="f-test">테스트</label><label for="f-ops">배포·운영</label><label for="f-cs">CS</label></div>
<div class="ll-timeline">
<div class="ll-month">2026.10</div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">10-30</span><a href="../LearnLog/BKT로-개념별-숙련도-추적하기---러닝메이트-수준-맞추기">BKT 숙련도 추적 — 러닝메이트 수준 맞추기</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="설계"><span class="ll-date">10-30</span><a href="../LearnLog/연습문제-출제-개선---개념-태깅과-학습-컨텍스트">연습문제 출제 개선 — 개념 태깅·학습 컨텍스트</a><span class="ll-tag" data-tag="설계">설계</span></div>
<div class="ll-row" data-tag="AI/RAG"><span class="ll-date">10-30</span><a href="../LearnLog/답변-라우팅-개선---질문-의도와-예제-스택-분리">답변 라우팅 — 질문 의도·예제 스택 분리</a><span class="ll-tag" data-tag="AI/RAG">AI/RAG</span></div>
<div class="ll-row" data-tag="테스트"><span class="ll-date">10-26</span><a href="../LearnLog/연습문제-서비스-테스트-보강---커버리지-20-percent--%3E84-percent">연습문제 테스트 보강 — 커버리지 20%→84%</a><span class="ll-tag" data-tag="테스트">테스트</span></div>
<div class="ll-row" data-tag="테스트"><span class="ll-date">10-26</span><a href="../LearnLog/테스트-커버리지와-Ruff-정적-분석---CI-코드-품질-자동화">pytest-cov + Ruff — CI 코드 품질 자동화</a><span class="ll-tag" data-tag="테스트">테스트</span></div>
<div class="ll-month">2026.09</div>
<div class="ll-row" data-tag="AI/검증"><span class="ll-date">09-11</span><a href="../LearnLog/멀티에이전트-작업을-기록으로-남기기---진행판과-Codex-브릿지-인계">멀티에이전트 기록 — 진행판·Codex 인계</a><span class="ll-tag" data-tag="AI/검증">AI/검증</span></div>
<div class="ll-row" data-tag="배포·운영"><span class="ll-date">09-11</span><a href="../LearnLog/쓰던-모델-4개가-한꺼번에-죽었다---교체와-CI가-못-잡은-이유">모델 4개 사망 — 교체와 CI 사각지대</a><span class="ll-tag" data-tag="배포·운영">배포·운영</span></div>
<div class="ll-row" data-tag="AI/검증"><span class="ll-date">09-08</span><a href="../LearnLog/선택지-문제-품질-게이트---멀티에이전트로-설계-검토하기">선택지 품질 검증 — 멀티에이전트 검토</a><span class="ll-tag" data-tag="AI/검증">AI/검증</span></div>
<div class="ll-month">2026.07</div>
<div class="ll-row" data-tag="설계"><span class="ll-date">07-03</span><a href="../LearnLog/코드-청소---중복·죽은-경로·조용히-저장되던-버그">코드 청소 — 죽은 경로·조용한 버그</a><span class="ll-tag" data-tag="설계">설계</span></div>
<div class="ll-month">2026.06</div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">06-28</span><a href="../LearnLog/일일-학습일지">일일 학습일지 — 하루 단위 회고</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="CS"><span class="ll-date">06-18</span><a href="../LearnLog/LLM-추론에서-입력은-싸고-출력이-비싸다">LLM 추론 — 입력은 싸고 출력이 비싸다</a><span class="ll-tag" data-tag="CS">CS</span></div>
<div class="ll-row" data-tag="AI/검증"><span class="ll-date">06-16</span><a href="../LearnLog/환각-방어---예방·검출·표시-3단">환각 방어 — 예방·검출·표시 3단</a><span class="ll-tag" data-tag="AI/검증">AI/검증</span></div>
<div class="ll-row" data-tag="AI/RAG"><span class="ll-date">06-11</span><a href="../LearnLog/pgvector-하이브리드-RAG---FTS+벡터-RRF-결합">pgvector 하이브리드 RAG — FTS+벡터 RRF</a><span class="ll-tag" data-tag="AI/RAG">AI/RAG</span></div>
<div class="ll-row" data-tag="AI/RAG"><span class="ll-date">06-11</span><a href="../LearnLog/LangGraph-라우팅-에이전트---질문별-조건-분기">LangGraph 라우팅 — 질문별 조건 분기</a><span class="ll-tag" data-tag="AI/RAG">AI/RAG</span></div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">06-10</span><a href="../LearnLog/꼬리질문---self-FK-질문-트리-구현">꼬리질문 — self-FK 질문 트리</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="AI/검증"><span class="ll-date">06-04</span><a href="../LearnLog/correct_index-런타임-가드-—-정답-인덱스-정합성-검증">런타임 가드 — 인덱스·값 불일치 0/91</a><span class="ll-tag" data-tag="AI/검증">AI/검증</span></div>
<div class="ll-month">2026.05</div>
<div class="ll-row" data-tag="AI/RAG"><span class="ll-date">05-30</span><a href="../LearnLog/RAG-검색-파이프라인-개선-—-한국어-질문이-엉뚱한-결과를-부르던-문제">RAG 검색 개선 — 한국어 질문 정확도 복원</a><span class="ll-tag" data-tag="AI/RAG">AI/RAG</span></div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">05-21</span><a href="../LearnLog/메타인지-학습-UX-재설계---안-쓰는-기능을-다시-만들기">메타인지 UX 재설계 — 안 쓰는 기능 다시 만들기</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="배포·운영"><span class="ll-date">05-17</span><a href="../LearnLog/Gunicorn-워커-타임아웃-트러블슈팅---스트리밍-응답-SIGKILL">Gunicorn 워커 SIGKILL 디버깅</a><span class="ll-tag" data-tag="배포·운영">배포·운영</span></div>
<div class="ll-row" data-tag="배포·운영"><span class="ll-date">05-06</span><a href="../LearnLog/PostgreSQL-버전-불일치-트러블슈팅---dbpull-실패">PostgreSQL 18 버전 불일치 트러블슈팅</a><span class="ll-tag" data-tag="배포·운영">배포·운영</span></div>
<div class="ll-month">2026.04</div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">04-28</span><a href="../LearnLog/통계-대시보드-+-Streak(불꽃)-시스템-구현">통계 대시보드 + Streak 시스템</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="CS"><span class="ll-date">04-28</span><a href="../LearnLog/싱글턴-패턴---Streak-모델-적용">싱글턴 패턴 — Streak 모델 적용</a><span class="ll-tag" data-tag="CS">CS</span></div>
<div class="ll-row" data-tag="성능"><span class="ll-date">04-25</span><a href="../LearnLog/LLM-공급자-하이브리드-전환---Groq-+-Mistral-속도·품질-벤치마크">LLM 하이브리드 전환 — Groq + Mistral</a><span class="ll-tag" data-tag="성능">성능</span></div>
<div class="ll-row" data-tag="성능"><span class="ll-date">04-25</span><a href="../LearnLog/LLM-응답-속도-최적화---병렬화,-프롬프트-경량화,-스트리밍">답변 생성 최적화 — 52.6s→37.3s</a><span class="ll-tag" data-tag="성능">성능</span></div>
<div class="ll-row" data-tag="AI/검증"><span class="ll-date">04-20</span><a href="../LearnLog/프롬프트-변경-효과-측정---correct_index-오류율-비교-테스트">프롬프트 변경 효과 측정 — 오류율 비교</a><span class="ll-tag" data-tag="AI/검증">AI/검증</span></div>
<div class="ll-row" data-tag="AI/검증"><span class="ll-date">04-20</span><a href="../LearnLog/프롬프트-검증-재설계---pytest를-버리고-실험-스크립트로">검증 재설계 — pytest→실험 스크립트</a><span class="ll-tag" data-tag="AI/검증">AI/검증</span></div>
<div class="ll-month">2026.03</div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">03-26</span><a href="../LearnLog/간격-반복-연습문제---자동-출제·채점">간격 반복 연습문제 — 자동 출제·채점</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="테스트"><span class="ll-date">03-13</span><a href="../LearnLog/GitHub-Actions로-테스트자동화">GitHub Actions CI — 자동 테스트·백업</a><span class="ll-tag" data-tag="테스트">테스트</span></div>
<div class="ll-row" data-tag="배포·운영"><span class="ll-date">03-13</span><a href="../LearnLog/render-배포웹-슬립-방지">배포 웹 슬립 방지 — 콜드스타트 제거</a><span class="ll-tag" data-tag="배포·운영">배포·운영</span></div>
<div class="ll-month">2026.02</div>
<div class="ll-row" data-tag="배포·운영"><span class="ll-date">02-27</span><a href="../LearnLog/Render-무료-배포-+-DB-동기화-+-자동-백업-구현">Render 배포 + DB 동기화 + 자동 백업</a><span class="ll-tag" data-tag="배포·운영">배포·운영</span></div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">02-12</span><a href="../LearnLog/학습로그-검색-기능---Full-Text-Search-구현">Full-Text Search — 한국어 키워드 검색</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="테스트"><span class="ll-date">02-09</span><a href="../LearnLog/log-list-API-테스트-작성">log list API 테스트 작성</a><span class="ll-tag" data-tag="테스트">테스트</span></div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">02-05</span><a href="../LearnLog/SSE-진행-스트리밍---프로그레스바·진행로그">SSE 진행 스트리밍 — 프로그레스바·진행로그</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="AI/RAG"><span class="ll-date">02-02</span><a href="../LearnLog/검색-도메인-자동-매핑---출처-판단-개선">검색 도메인 자동 매핑 — 출처 판단</a><span class="ll-tag" data-tag="AI/RAG">AI/RAG</span></div>
<div class="ll-month">2026.01</div>
<div class="ll-row" data-tag="설계"><span class="ll-date">01-30</span><a href="../LearnLog/Django-모델-설계-및-마이그레이션-초기화">Django 모델 설계 + 마이그레이션</a><span class="ll-tag" data-tag="설계">설계</span></div>
<div class="ll-row" data-tag="설계"><span class="ll-date">01-30</span><a href="../LearnLog/LearningLog-모델-필드-설계">LearningLog 모델 필드 설계</a><span class="ll-tag" data-tag="설계">설계</span></div>
<div class="ll-row" data-tag="설계"><span class="ll-date">01-30</span><a href="../LearnLog/학습-로그-서비스-계층-설계-및-구현">서비스 계층 설계 — API→가공→저장</a><span class="ll-tag" data-tag="설계">설계</span></div>
<div class="ll-row" data-tag="배포·운영"><span class="ll-date">01-23</span><a href="../LearnLog/vscode에서-Docker-컨테이너-디버깅하기">Docker 컨테이너 원격 디버깅</a><span class="ll-tag" data-tag="배포·운영">배포·운영</span></div>
</div>
</div>
