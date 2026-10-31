# 📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템

[https://github.com/aengu/learn-log](https://github.com/aengu/learn-log)

[Learn Log - AI 개발 지식 베이스](https://learn-log.onrender.com/)

## 🎯 프로젝트 개요

개발 중 기술적 질문을 검색하면 AI가 참고 자료와 함께 답을 정리하고, 저장한 학습 로그를 RAG로 재활용합니다. 간격 반복 연습문제에 개념별 숙련도 추적과 사용자 수준에 맞춘 AI 러닝메이트를 연결한 개인 학습 서비스입니다.

**핵심 가치**: 검색 → 정리 → 복습 → 재활용(RAG)의 학습 루프를 하나의 시스템 안에서 완결

> 개발하면서 직접 사용하는 개인 학습 도구입니다. 사용 중 느낀 불편을 기능 개선으로 이어가며, 성능·출력 정합성은 벤치마크로, 코드 동작은 테스트와 정적 검사로 확인합니다. BKT 숙련도는 고정 가정값 기반의 초기 추정이며, 학습 효과 검증과는 구분합니다.

<img src="LearnLog/attachments/Learn-Log---AI-개발-지식-베이스.gif" width="720" alt="LearnLog 실행 화면" />

<div class="ll-stats">
  <div class="ll-stat"><b>진행 중</b><span>지속 개선 (2026.1–현재)</span></div>
  <div class="ll-stat"><b>38편</b><span>개발 일지</span></div>
  <div class="ll-stat"><b>16개</b><span>벤치마크·검증 스크립트</span></div>
  <div class="ll-stat"><b>0/91</b><span>정답 인덱스·값 불일치 (20회 생성)</span></div>
  <div class="ll-stat"><b>52.6→37.3s</b><span>답변 생성 단축 · 당시 Mistral</span></div>
  <div class="ll-stat"><b>230개</b><span>일반 테스트 통과 · CI 품질 검사</span></div>
</div>

---

## 🏗 아키텍처

<div class="rs-flow">
<svg class="flow" viewBox="0 0 1600 540" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="학습기록을 먼저 검색하고 라우터가 웹검색 필요 여부를 판단합니다. 답변 생성 후 사용자에게 스트리밍하고 저장하며, 저장 후 백그라운드 모순 검사와 요청 시 복습 문제 생성으로 이어집니다. PPT와 동일한 카드형 아키텍처 도식입니다.">
<rect width="1600" height="540" fill="#F5F5F5"/>
<g transform="translate(0 -240)">
<rect x="56" y="402" width="150" height="96" rx="14" fill="#101828" stroke="#FFFFFF" stroke-width="1"/>
<text style="fill:#FFFFFF" x="131" fill="#FFFFFF" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="131" y="456">사용자 질문</tspan></text>
<rect x="260" y="364" width="220" height="170" rx="14" fill="#EAF1FF" stroke="#315EAE" stroke-width="1"/>
<text style="fill:#315EAE" x="370" fill="#315EAE" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="370" y="430">학습기록 검색</tspan><tspan style="fill:inherit" x="370" y="455">FTS + Vector</tspan><tspan style="fill:inherit" x="370" y="480">항상 먼저 실행</tspan></text>
<rect x="550" y="364" width="210" height="170" rx="14" fill="#F0EAFF" stroke="#6941C6" stroke-width="1"/>
<text style="fill:#6941C6" x="655" fill="#6941C6" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="655" y="442.5">검색 결과 판단</tspan><tspan style="fill:inherit" x="655" y="467.5">웹이 필요한가?</tspan></text>
<rect x="820" y="590" width="230" height="108" rx="14" fill="#E7F8F1" stroke="#087A5B" stroke-width="1"/>
<text style="fill:#087A5B" x="935" fill="#087A5B" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="935" y="637.5">공식 웹 자료 검색</tspan><tspan style="fill:inherit" x="935" y="662.5">필요할 때만</tspan></text>
<rect x="850" y="364" width="220" height="170" rx="14" fill="#101828" stroke="#FFFFFF" stroke-width="1"/>
<text style="fill:#FFFFFF" x="960" fill="#FFFFFF" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="960" y="442.5">AI 답변 생성</tspan><tspan style="fill:inherit" x="960" y="467.5">gpt-oss-120b</tspan></text>
<rect x="1160" y="260" width="250" height="105" rx="14" fill="#E7F8F1" stroke="#087A5B" stroke-width="1"/>
<text style="fill:#087A5B" x="1285" fill="#087A5B" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="1285" y="306">답변 스트리밍</tspan><tspan style="fill:inherit" x="1285" y="331">사용자에게 먼저 전달</tspan></text>
<rect x="1160" y="445" width="250" height="105" rx="14" fill="#EAF1FF" stroke="#315EAE" stroke-width="1"/>
<text style="fill:#315EAE" x="1285" fill="#315EAE" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="1285" y="491">학습기록 저장</tspan><tspan style="fill:inherit" x="1285" y="516">PostgreSQL</tspan></text>
<rect x="1090" y="664" width="220" height="92" rx="14" fill="#FFF0E5" stroke="#B54708" stroke-width="1"/>
<text style="fill:#B54708" x="1200" fill="#B54708" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="1200" y="703.5">백그라운드 모순 검사</tspan><tspan style="fill:inherit" x="1200" y="728.5">Qwen · Groq</tspan></text>
<rect x="1360" y="664" width="180" height="92" rx="14" fill="#F0EAFF" stroke="#6941C6" stroke-width="1"/>
<text style="fill:#6941C6" x="1450" fill="#6941C6" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="17" font-weight="700"><tspan style="fill:inherit" x="1450" y="703.5">복습 문제</tspan><tspan style="fill:inherit" x="1450" y="728.5">요청할 때 생성</tspan></text>
<path d="M 206 450 L 260 450" stroke="#D0D5DD" stroke-width="2" fill="none"/>
<path d="M 249.60769515458674 456 L 260 450" stroke="#D0D5DD" stroke-width="2" fill="none"/>
<path d="M 260 450 L 249.60769515458674 444" stroke="#D0D5DD" stroke-width="2" fill="none"/>
<path d="M 480 450 L 550 450" stroke="#315EAE" stroke-width="2" fill="none"/>
<path d="M 539.6076951545867 456 L 550 450" stroke="#315EAE" stroke-width="2" fill="none"/>
<path d="M 550 450 L 539.6076951545867 444" stroke="#315EAE" stroke-width="2" fill="none"/>
<path d="M 760 420 L 850 420" stroke="#6941C6" stroke-width="2" fill="none"/>
<path d="M 839.6076951545867 426 L 850 420" stroke="#6941C6" stroke-width="2" fill="none"/>
<path d="M 850 420 L 839.6076951545867 414" stroke="#6941C6" stroke-width="2" fill="none"/>
<path d="M 655 534 L 655 644" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 655 644 L 820 644" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 809.6076951545867 650 L 820 644" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 820 644 L 809.6076951545867 638" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 935 590 L 960 534" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 961.2423954909707 545.935512282429 L 960 534" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 960 534 L 950.2847409017206 541.0437021979424" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 1070 410 L 1160 312" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 1157.389772376005 323.71267312576146 L 1160 312" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 1160 312 L 1148.5514137148698 315.5958131308413" stroke="#087A5B" stroke-width="2" fill="none"/>
<path d="M 1070 488 L 1160 498" stroke="#315EAE" stroke-width="2" fill="none"/>
<path d="M 1149.0086680919248 502.8156643245277 L 1160 498" stroke="#315EAE" stroke-width="2" fill="none"/>
<path d="M 1160 498 L 1150.333846404823 490.8890595084443" stroke="#315EAE" stroke-width="2" fill="none"/>
<path d="M 1280 550 L 1200 664" stroke="#B54708" stroke-width="2" fill="none"/>
<path d="M 1201.0582673408906 652.0467548240988 L 1200 664" stroke="#B54708" stroke-width="2" fill="none"/>
<path d="M 1200 664 L 1210.8809476504393 658.939863813256" stroke="#B54708" stroke-width="2" fill="none"/>
<path d="M 1350 550 L 1450 664" stroke="#6941C6" stroke-width="2" fill="none"/>
<path d="M 1438.63636648832 660.1441170385731 L 1450 664" stroke="#6941C6" stroke-width="2" fill="none"/>
<path d="M 1450 664 L 1447.6574758427753 652.2308632188755" stroke="#6941C6" stroke-width="2" fill="none"/>
<text style="fill:#6941C6" x="813" y="407" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="12" font-weight="700" fill="#6941C6">웹 생략</text>
<text style="fill:#087A5B" x="719" y="627" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="12" font-weight="700" fill="#087A5B">웹 필요</text>
<text style="fill:#6941C6" x="1403" y="611" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="12" font-weight="700" fill="#6941C6">나중에 생성</text>
</g>
</svg>
</div>

학습기록을 먼저 검색하고, 그 결과를 본 라우터가 기록 활용 여부와 웹검색 필요 여부를 판단합니다. 생성한 답변은 사용자에게 스트리밍하며, 저장 후 모순 검사는 백그라운드에서 실행합니다. 복습 문제는 요청할 때 생성하고, 저장된 기록은 다음 질문의 검색에 재활용합니다.

*구현: 라우팅 LangGraph · 하이브리드 검색 pgvector+FTS · 답변 Mistral · 검증·경량작업 Groq · 웹검색 Tavily*

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
<td>답변이 저장돼 연습문제로 암기되는 구조라 환각이 치명적인데, 무료 티어 모델의 환각 자체는 막을 수 없다. 예방(grounding)·검출(생성과 <b>다른 모델</b>로 저장 후 비동기 모순 검사)·표시(출처·검증 배지) 3단으로 다루고, 그 Judge까지 Claude로 66건 교차검증.</td>
<td><span class="ll-num">응답 안 막는 검증</span><a href="../LearnLog/환각-방어---예방·검출·표시-3단">상세 →</a></td>
</tr>
<tr>
<td>🧪 <b>LLM 검증 체계</b><small>채점 스크립트의 오판 발견 · 교체</small></td>
<td>프롬프트 개선 효과를 측정하니 오히려 악화로 나왔다 — 원시 응답을 전수 확인해 보니 "오류"의 75%가 채점 스크립트의 오판. 채점기를 먼저 고치고, 스킵률 90%인 정규식 채점을 다른 모델의 LLM 교차 채점으로 교체해 전수 판정.</td>
<td><span class="ll-num">Judge 오류 판정 10%→5%</span><small>8/80 → 4/80 문항 · 모호한 판정 포함</small><a href="../LearnLog/프롬프트-검증-재설계---pytest를-버리고-실험-스크립트로">상세 →</a></td>
</tr>
<tr>
<td>🔒 <b>런타임 가드</b><small>출력 자가검증 + 실패 시 재생성</small></td>
<td>정답 값과 선택지 위치의 불일치를 코드로 검사하고, 불일치 문항은 제외한 뒤 재생성하도록 구현. 두 필드가 같은 오답을 가리키면 통과할 수 있어, 내부 일관성과 사실 정확도를 구분했습니다.</td>
<td><span class="ll-num">인덱스·값 불일치 0/91건</span><small>20회 생성 · 최종 문항 기준<br/>해당 실행에서 재생성 미발생<br/>가드의 제거 효과는 별도 검증 필요</small><a href="../LearnLog/correct_index-런타임-가드-—-정답-인덱스-정합성-검증">상세 →</a></td>
</tr>
<tr>
<td>⚡ <b>속도 vs 품질</b><small>모델 분리 + 병렬화 + 스트리밍</small></td>
<td>작업별 시간을 측정해 답변 생성 병목을 확인. 프롬프트 경량화로 생성 시간을 줄이고, 독립적인 태그·마크다운 후처리를 병렬화(2.89s → 1.01s). SSE는 완료 시간 단축과 별개로 생성 중 답변을 전달합니다.</td>
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

---

## ✨ 주요 기능

### AI 답변 + 공식 레퍼런스 정리
필요할 때 Tavily로 웹 자료를 검색하고, Groq의 생성 모델로 답변을 스트리밍한 뒤 마크다운으로 정리합니다. 출처를 함께 보관하되, 검색된 자료가 답변의 모든 주장을 보증하는 것은 아닙니다. *(위 실행 화면)*

### 과거 학습기록 재활용 (RAG)
저장·태그 분류된 학습기록을 키워드 + 의미(pgvector)로 검색해 답변 컨텍스트에 주입합니다. "N+1 문제"로 저장한 기록을 "ORM이 반복 호출돼 느린 문제" 질문으로 찾아옵니다 — 키워드가 안 겹쳐도.

### 질문별 경로 라우팅
라우터가 **웹검색 필요 여부·학습기록 사용 여부**와 함께 **설명 초점·예제 스택(SQL/Python/Django/auto)**을 선택합니다. SQL로 충분한 질문에 Django 예제를 억지로 붙이지 않도록 생성 지침을 분기하며, 기존 스트리밍은 유지합니다.

### 환각 방어
생성과 다른 모델로 모순을 **비동기** 검증하고 출처 배지를 표시합니다. 검증이 답변 속도를 막지 않게 분리했습니다.

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
