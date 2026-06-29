# 📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템

[https://github.com/aengu/learn-log](https://github.com/aengu/learn-log)

[Learn Log - AI 개발 지식 베이스](https://learn-log.onrender.com/)

## 🎯 프로젝트 개요

개발 중 기술적 질문을 검색하면, AI가 공식 레퍼런스와 함께 답을 마크다운으로 정리해주고, 저장된 학습 로그를 다시 검색(RAG)해 새 답변에 활용하며, 간격 반복 연습문제로 복습까지 이어지는 학습 아카이브 시스템입니다.

**핵심 가치**: 검색 → 정리 → 복습 → 재활용(RAG)의 학습 루프를 하나의 시스템 안에서 완결

> 제가 개발하면서 매일 직접 쓰는 개인 학습 도구입니다. 토이 프로젝트로 끝내지 않고, 실제 사용 중 느낀 불편을 기능 개선으로 이어가고 있습니다.

<img src="LearnLog/attachments/Learn-Log---AI-개발-지식-베이스.gif" width="720" alt="LearnLog 실행 화면" />

<div class="ll-stats">
  <div class="ll-stat"><b>5개월</b><span>지속 개발 (2026.1–6)</span></div>
  <div class="ll-stat"><b>28편</b><span>개발 일지</span></div>
  <div class="ll-stat"><b>0%</b><span>출제 정답 오류율 · 런타임 검증</span></div>
  <div class="ll-stat"><b>68→37s</b><span>응답 단축</span></div>
  <div class="ll-stat"><b>73개</b><span>테스트</span><small>모듈 9개</small></div>
</div>

---

## 🏗 아키텍처

```mermaid
flowchart LR
    U[사용자 질문] --> R{질문 분석<br/>경로 결정}
    R -->|학습기록으로 충분| RAG[(학습기록 검색<br/>키워드 + 의미 결합)]
    R -->|웹 자료 필요| T[웹 문서 검색]
    RAG --> G[AI 답변 생성]
    T --> G
    G --> J[환각 검증<br/>다른 모델로 교차검사]
    G -->|실시간 스트리밍| U
    G --> DB[(학습기록 저장)]
    DB --> EX[복습 연습문제 생성]
    DB -.->|재활용| RAG
    classDef key fill:#d9ccf5,stroke:#7c5cbf,color:#332456,font-weight:bold
    class R,RAG,J key
```

라우터가 질문마다 경로를 정하고(웹 생략 / 무관한 기록 차단), 과거 학습기록을 검색해 답변 컨텍스트를 채우며, 생성과 다른 모델로 환각을 비동기 검증합니다.

*구현: 라우팅 LangGraph · 하이브리드 검색 pgvector+FTS · 답변 Mistral · 검증·경량작업 Groq · 웹검색 Tavily*

---

## ✨ 주요 기능

### AI 답변 + 공식 레퍼런스 정리
질문하면 Tavily로 공식 문서를 찾고, Mistral이 답변을, Groq가 노션 스타일 마크다운 변환을 맡아 레퍼런스가 포함된 한 문서로 정리합니다. *(위 실행 화면)*

### 과거 학습기록 재활용 (RAG)
저장·태그 분류된 학습기록을 키워드 + 의미(pgvector)로 검색해 답변 컨텍스트에 주입합니다. "N+1 문제"로 저장한 기록을 "ORM이 반복 호출돼 느린 문제" 질문으로 찾아옵니다 — 키워드가 안 겹쳐도.

### 질문별 경로 라우팅
라우터가 질문을 보고 **웹검색 생략**(기록으로 충분) · **무관 기록 차단**을 판단합니다. 직선 파이프라인을 조건 분기 그래프(LangGraph)로 전환했습니다.

### 환각 방어
생성과 다른 모델로 모순을 **비동기** 검증하고 출처 배지를 표시합니다. 검증이 답변 속도를 막지 않게 분리했습니다.

### 간격 반복 연습문제
저장한 기록을 정말 이해했는지 두 유형으로 출제하고, 1·3·7·14·30일 간격으로 복습을 관리합니다.

<div class="ll-shots">
<img src="LearnLog/attachments/quiz-choice.png" alt="선택지 고르기 — 단계별 경로 추적" />
<img src="LearnLog/attachments/quiz-write.png" alt="직접 답하기 — 자가채점 + 모범답안 + AI 피드백" />
</div>

### 통계 대시보드 + Streak
학습량 · 정답률 · 연속 학습일수(Streak)를 잔디 스타일로 시각화합니다.

<img class="ll-shot" src="LearnLog/attachments/dashboard.png" width="600" alt="통계 대시보드" />

## 🛠 기술 스택

### **Backend**

- **Django 5.x**: 웹 프레임워크
- **Django REST Framework**: API 엔드포인트 구현
- **PostgreSQL 18**: 검색 히스토리·메타데이터 저장, Full-Text Search + **pgvector 하이브리드(벡터+키워드) 검색**
- **LangGraph**: 질문별 조건 분기 라우팅 에이전트 (검색→생성 파이프라인 제어)

### **Frontend**

- **Django Template** + **HTMX**: SPA 없이 서버 렌더링 기반으로 SSE 스트리밍, 무한스크롤, 부분 페이지 갱신 구현
- **Tailwind CSS**: 유틸리티 클래스 기반 CSS 프레임워크

### **Testing & CI**

- **pytest** + **pytest-django**: 테스트 러너 및 Django 통합
- **factory_boy**: 테스트 데이터 팩토리
- **GitHub Actions**: push/PR 시 자동 테스트 실행

### **Deployment**

- **Docker** + **Docker Compose**: 컨테이너화 및 개발 환경 구성
- **Render**: 프로덕션 배포 (Web Service + Managed PostgreSQL)

---

## 🤖 LLM·검색 API

작업 성격에 맞춰 3개 API를 분리해서 씁니다.

- **Tavily** — 공식 문서 웹 검색·발췌 (RAG의 웹 소스)
- **Mistral Large** — 답변 생성 (개념 깊이·한국어 품질 우수)
- **Groq (Llama 3.3)** — 태그 추출·마크다운 변환·라우팅 판단 등 경량·고속 작업

> 초기 Groq 단독 → 품질 위해 Mistral 도입, 작업별 하이브리드로 분리. → [[LLM 공급자 하이브리드 전환 - Groq + Mistral 속도·품질 벤치마크|벤치마크]]

---

## 주요 기술적 도전

| 주제 | 문제/과제 | 접근 | 결과 |
|------|-----------|------|------|
| 학습기록 재활용 (RAG) | 저장한 학습기록이 새 답변 생성에 안 쓰이고 묻힘 | pgvector 임베딩 + 기존 FTS를 RRF로 결합, top-3을 답변 프롬프트에 주입 | 키워드가 안 겹쳐도 의미로 검색 (추가 0.65s, 전체의 2%) → [[pgvector 하이브리드 RAG - FTS+벡터 RRF 결합\|상세]] |
| 질문별 경로 라우팅 | 모든 질문이 같은 직선 경로 → 불필요한 웹검색·무관 기록 주입 | LangGraph 조건 분기 — 라우터(Groq)가 웹검색 생략·무관 기록 차단을 판단, 기존 서비스 메서드를 노드로 재사용 | 질문별 경로 최적화 (웹 생략 시 단축) → [[LangGraph 라우팅 에이전트 - 질문별 조건 분기\|상세]] |
| 환각 방어 | 무료 티어 모델 환각 + 오염된 과거 답변 재사용 위험 | 예방(grounding) · 검출(생성과 다른 모델로 비동기 모순 검증) · 표시(출처 배지) 3단 | 답변 속도 안 막는 검증 + 출처 신뢰도 표시 → [[환각 방어 - 예방·검출·표시 3단\|상세]] |
| LLM 출제 정답 검증 | LLM이 생성한 연습문제의 정답(correct_index)이 틀림 | 반복 실험 + 별도 LLM 자동 판정 + 런타임 가드(결정적 검증·재생성) | 출제 정답 오류 10%→5%→**0%** → [[프롬프트 변경 효과 측정 - correct_index 오류율 비교 테스트\|상세]] / [[correct_index 런타임 가드 — 자가검증으로 환각 0%에 수렴\|0%까지]] |
| LLM 속도 vs 품질 균형 | Mistral 도입 후 응답 68초 | 작업별 벤치마크 → Groq+Mistral 하이브리드 분리 → 병렬 처리·프롬프트 경량화·스트리밍 | 68초→**37초** 단축 + 체감 속도 개선 → [[LLM 공급자 하이브리드 전환 - Groq + Mistral 속도·품질 벤치마크\|하이브리드]] / [[LLM 응답 속도 최적화 - 병렬화, 프롬프트 경량화, 스트리밍\|코드 최적화]] |

---

## 개발 후기

**왜 만들었나** — 검색해서 저장만 하고 다시 안 보는 문제가 있었습니다. 그 순간엔 이해한 것 같은데 며칠 뒤 같은 걸 또 검색하고 있었어요. "검색 → 정리 → 복습"이 한 곳에서 도는 시스템이 필요했습니다.

**실제로 쓰나** — 남을 위한 서비스가 아니라 매일 직접 씁니다. 연습문제 정답률 40% — 저장만 하고 제대로 이해 못 한 걸 숫자로 확인하게 된 것이 가장 큰 수확이었습니다.

**아쉬운 점** — 무료 LLM 티어의 속도 한계(약 30초)는 병렬 호출·경량화·스트리밍으로 체감을 줄였지만 근본 한계는 남아 있습니다.

---

## 개발 타임라인

2026년 1~6월, 약 5개월간 28편 — 검색 아카이브에서 RAG·환각 방어까지 꾸준히 발전시켰습니다. 태그를 누르면 영역별로 필터됩니다.

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
<div class="ll-month">2026.06</div>
<div class="ll-row" data-tag="CS"><span class="ll-date">06-18</span><a href="../LearnLog/LLM-추론에서-입력은-싸고-출력이-비싸다">LLM 추론 — 입력은 싸고 출력이 비싸다</a><span class="ll-tag" data-tag="CS">CS</span></div>
<div class="ll-row" data-tag="AI/검증"><span class="ll-date">06-16</span><a href="../LearnLog/환각-방어---예방·검출·표시-3단">환각 방어 — 예방·검출·표시 3단</a><span class="ll-tag" data-tag="AI/검증">AI/검증</span></div>
<div class="ll-row" data-tag="AI/RAG"><span class="ll-date">06-11</span><a href="../LearnLog/pgvector-하이브리드-RAG---FTS+벡터-RRF-결합">pgvector 하이브리드 RAG — FTS+벡터 RRF</a><span class="ll-tag" data-tag="AI/RAG">AI/RAG</span></div>
<div class="ll-row" data-tag="AI/RAG"><span class="ll-date">06-11</span><a href="../LearnLog/LangGraph-라우팅-에이전트---질문별-조건-분기">LangGraph 라우팅 — 질문별 조건 분기</a><span class="ll-tag" data-tag="AI/RAG">AI/RAG</span></div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">06-10</span><a href="../LearnLog/꼬리질문---self-FK-질문-트리-구현">꼬리질문 — self-FK 질문 트리</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="AI/검증"><span class="ll-date">06-04</span><a href="../LearnLog/correct_index-런타임-가드-—-자가검증으로-환각-0-percent에-수렴">런타임 가드 — 자가검증으로 환각 0%</a><span class="ll-tag" data-tag="AI/검증">AI/검증</span></div>
<div class="ll-month">2026.05</div>
<div class="ll-row" data-tag="AI/RAG"><span class="ll-date">05-30</span><a href="../LearnLog/RAG-검색-파이프라인-개선-—-한국어-질문이-엉뚱한-결과를-부르던-문제">RAG 검색 개선 — 한국어 질문 정확도 복원</a><span class="ll-tag" data-tag="AI/RAG">AI/RAG</span></div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">05-21</span><a href="../LearnLog/메타인지-학습-UX-재설계---안-쓰는-기능을-다시-만들기">메타인지 UX 재설계 — 안 쓰는 기능 다시 만들기</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="배포·운영"><span class="ll-date">05-17</span><a href="../LearnLog/Gunicorn-워커-타임아웃-트러블슈팅---스트리밍-응답-SIGKILL">Gunicorn 워커 SIGKILL 디버깅</a><span class="ll-tag" data-tag="배포·운영">배포·운영</span></div>
<div class="ll-row" data-tag="배포·운영"><span class="ll-date">05-06</span><a href="../LearnLog/PostgreSQL-버전-불일치-트러블슈팅---dbpull-실패">PostgreSQL 18 버전 불일치 트러블슈팅</a><span class="ll-tag" data-tag="배포·운영">배포·운영</span></div>
<div class="ll-month">2026.04</div>
<div class="ll-row" data-tag="기능구현"><span class="ll-date">04-28</span><a href="../LearnLog/통계-대시보드-+-Streak(불꽃)-시스템-구현">통계 대시보드 + Streak 시스템</a><span class="ll-tag" data-tag="기능구현">기능구현</span></div>
<div class="ll-row" data-tag="CS"><span class="ll-date">04-28</span><a href="../LearnLog/싱글턴-패턴---Streak-모델-적용">싱글턴 패턴 — Streak 모델 적용</a><span class="ll-tag" data-tag="CS">CS</span></div>
<div class="ll-row" data-tag="성능"><span class="ll-date">04-25</span><a href="../LearnLog/LLM-공급자-하이브리드-전환---Groq-+-Mistral-속도·품질-벤치마크">LLM 하이브리드 전환 — Groq + Mistral</a><span class="ll-tag" data-tag="성능">성능</span></div>
<div class="ll-row" data-tag="성능"><span class="ll-date">04-25</span><a href="../LearnLog/LLM-응답-속도-최적화---병렬화,-프롬프트-경량화,-스트리밍">응답 속도 최적화 — 68s→37s</a><span class="ll-tag" data-tag="성능">성능</span></div>
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
