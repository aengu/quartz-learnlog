# 신혜란

> **Python/Django 백엔드 개발자 — 금융 주문 시스템 운영 · LLM/RAG 서비스 개발**
>
> - 활성 고객 600+명·월 18만~27만 건 주문을 처리하는 주식 자동매매 서비스 개발·운영 — 주문 승인 시스템 설계, 동시성 제어·스케줄러 중복 실행·DB 커넥션 문제 해결, 후반 7개월 단독 운영
> - AI API 활용 개인 프로젝트([LearnLog](https://aengu.github.io/quartz-learnlog/)) — 하이브리드 검색(RAG)·조건 분기 라우팅·LLM 출력 검증, Docker/CI/CD 직접 설계
> - Django·DB 핵심 주제(ORM 최적화·트랜잭션·MVCC 등)를 학습하고, 개념 정리와 직접 실험을 병행해 [기술 글 12편으로 정리](https://aengu.github.io/quartz-learnlog/이력서/신혜란/What-I-Learned/)
> - AI 부트캠프 5인 팀 해커톤 — 수요예측 기반 식품 순환 플랫폼(잇다루프) 기획·화면 설계·백엔드 담당, 파트 간 함수 계약을 먼저 확정해 대기 없이 병렬 개발

---

# Contact

- Email: shr19970923@gmail.com
- GitHub: [https://github.com/aengu](https://github.com/aengu)
- Tech Notes: [https://aengu.github.io/quartz-learnlog/](https://aengu.github.io/quartz-learnlog/)
- 자기소개서: [[자기소개서]]

---

# Skills

| 분류       | 기술                                                        |
| -------- | --------------------------------------------------------- |
| Backend  | Python, Django, Django REST Framework                     |
| Database | PostgreSQL (Full-Text Search), MySQL                      |
| Infra    | Docker, Docker Compose, AWS (EC2, ELB, Auto Scaling, RDS) |
| CI/CD    | GitHub Actions, pytest, factory_boy                       |
| AI/API   | Mistral API (Mistral Large), Groq API (Llama 3.3), Tavily API |
| etc      | Git, Jira, Confluence                                     |

---

# 경력

## 주식회사 맥클로린 (2021.03 ~ 2022.08)

**큐앤에이소프트**(맥클로린 소속 사내 회사) — 퀀트 딥러닝 주식 자동매매 서비스 개발 및 운영

서비스 초기부터 참여하여 주문 시스템 개발과 운영 안정화를 담당했고, 후반 약 7개월은 단독으로 운영했습니다.
활성 고객 600+명 / 월 리밸런싱 시 약 18만~27만 건의 주문 처리.
→ [[큐앤에이소프트- 상세페이지]]

### 주문 시스템
- **주문 중복 집행 방지 (동시성 제어)**: 승인 주문을 집행으로 변환할 때 `select_for_update` 행 잠금 + 상태값 선점으로, 작업이 동시에 도는 환경에서 같은 주문의 이중 집행(= 고객 자산 이중 매매)을 차단
- **주문 승인 시스템 설계·도입**: 고객 사전 승인을 받아야 하는 규정에 맞춰 [생성 → 승인 → 체결 → 완료] 단계를 도입 → 리밸런싱 대량 주문의 오발주(휴먼 에러)를 사전 차단하고 그룹/고객별 모니터링 가능
- 월 18만~27만 건 대량 주문을 `bulk_create`/`bulk_update`로 일괄 처리해 DB 왕복 최소화

### 운영 안정화
- 리밸런싱 부하로 서비스가 느려져 **팀이 서비스·DB를 분리**(ELB·Auto Scaling·DB Router, 월 서버 비용 약 400만 → 200~300만 원 절감)했고, 그 분리로 새로 생긴 두 가지 안정성 문제를 직접 해결했습니다:
    - **스케줄러 중복 실행**: 배포 시 워커마다 스케줄러가 떠 같은 작업이 4회씩 실행되던 문제를, 별도 프로세스로 분리해 제거
    - **DB 커넥션 오류**: 거래 시간대(8~17시) 외 주문 DB가 내려가며 반복되던 lost connection을, 트랜잭션 종료 시 커넥션을 명시적으로 정리해 해소

### 기타
- 영업팀 상담 녹취 통화시간 자동 집계(ETL)로 매체별 상담 품질 측정 기반 마련

---

## 연세대학교 LandFlow 프로젝트 (2021.07 ~ 2021.11, 재직사 산학협력)

토석류 유동 시뮬레이션 Matlab GUI(App Designer) 개발 — 비개발 기획자와 협업해 요구사항을 화면으로 구체화
→ [[landflow- 상세페이지]]

---

# 프로젝트

## LearnLog — AI 개발 지식 베이스 (2026)

[GitHub](https://github.com/aengu/learn-log) | [배포 사이트](https://learn-log.onrender.com/) | [[📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템|포트폴리오]]

개발 중 기술적 질문을 검색하면 AI가 공식 레퍼런스 기반으로 답을 정리하고, 저장한 기록을 다시 검색해 새 답변에 활용하며 복습 문제까지 잇는 AI 학습 아카이브

<div class="rs-flow">
<svg class="flow" viewBox="0 0 700 208" role="img"
aria-label="사용자 질문을 라우터가 분석해 웹 문서 검색 또는 학습기록 검색으로 보내고, 그 결과로 AI가 답변을 생성한다. 답변은 다른 모델로 환각을 교차 검증하고 학습기록으로 저장되며, 저장된 기록은 복습 문제로 이어지는 동시에 다음 질문의 학습기록 검색에 재활용된다.">
<defs>
<marker id="a1" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="5.5" markerHeight="5.5" orient="auto-start-reverse">
<polygon class="f-h" points="0,0 10,5 0,10"/>
</marker>
<marker id="a2" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="5.5" markerHeight="5.5" orient="auto-start-reverse">
<polygon class="f-h k" points="0,0 10,5 0,10"/>
</marker>
</defs>

<rect class="f-box"   x="6"   y="76"  width="72"  height="36" rx="4"/>
<text class="f-t" x="42"  y="99"  text-anchor="middle">질문</text>

<rect class="f-box k" x="98"  y="76"  width="88"  height="36" rx="4"/>
<text class="f-t on" x="142" y="99"  text-anchor="middle">경로 결정</text>

<rect class="f-box"   x="210" y="22"  width="116" height="36" rx="4"/>
<text class="f-t" x="268" y="45"  text-anchor="middle">웹 문서 검색</text>

<rect class="f-box k" x="210" y="126" width="116" height="42" rx="4"/>
<text class="f-t on" x="268" y="144" text-anchor="middle">학습기록 검색</text>
<text class="f-s on" x="268" y="159" text-anchor="middle">키워드 + 의미</text>

<rect class="f-box"   x="352" y="76"  width="86"  height="36" rx="4"/>
<text class="f-t" x="395" y="99"  text-anchor="middle">답변 생성</text>

<rect class="f-box k" x="464" y="22"  width="110" height="42" rx="4"/>
<text class="f-t on" x="519" y="40"  text-anchor="middle">환각 검증</text>
<text class="f-s on" x="519" y="55"  text-anchor="middle">다른 모델 교차</text>

<rect class="f-box"   x="464" y="126" width="110" height="36" rx="4"/>
<text class="f-t" x="519" y="149" text-anchor="middle">학습기록 저장</text>

<rect class="f-box"   x="600" y="126" width="94"  height="36" rx="4"/>
<text class="f-t" x="647" y="149" text-anchor="middle">복습 문제</text>

<line     class="f-l" x1="78" y1="94" x2="94" y2="94" marker-end="url(#a1)"/>
<polyline class="f-l" points="186,88 198,88 198,40 206,40"    marker-end="url(#a1)"/>
<polyline class="f-l" points="186,100 198,100 198,147 206,147" marker-end="url(#a1)"/>
<polyline class="f-l" points="326,40 338,40 338,94 348,94"     marker-end="url(#a1)"/>
<polyline class="f-l" points="326,147 338,147 338,94"/>
<polyline class="f-l" points="438,88 450,88 450,43 460,43"     marker-end="url(#a1)"/>
<polyline class="f-l" points="438,100 450,100 450,144 460,144" marker-end="url(#a1)"/>
<line     class="f-l" x1="574" y1="144" x2="596" y2="144" marker-end="url(#a1)"/>

<polyline class="f-l k" points="519,162 519,186 268,186 268,172" marker-end="url(#a2)"/>
<text class="f-c" x="393" y="202" text-anchor="middle">다음 질문에 재활용 (RAG)</text>
</svg>
</div>

### 기술 스택

<div class="rs-stack">
<span class="rs-chip" data-k="1">Django 5</span><span class="rs-chip" data-k="1">DRF</span><span class="rs-chip" data-k="1">PostgreSQL</span><span class="rs-chip">FTS</span><span class="rs-chip">pgvector</span><span class="rs-chip" data-k="1">LangGraph</span><span class="rs-chip">Groq</span><span class="rs-chip">Mistral</span><span class="rs-chip">Tavily</span><span class="rs-chip" data-k="1">Docker</span><span class="rs-chip">HTMX</span><span class="rs-chip">pytest</span><span class="rs-chip">factory_boy</span><span class="rs-chip">GitHub Actions</span><span class="rs-chip">Render</span>
</div>

### 주요 구현

<div class="rs-impl">

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">하이브리드 검색 (RAG)</span><span class="rs-metric">추가 지연 0.65s · 전체의 2%</span></div>
<p class="rs-desc">PostgreSQL FTS(키워드)와 pgvector(임베딩)를 RRF로 결합해 과거 학습기록을 답변 생성에 주입. 키워드가 겹치지 않아도 의미 기반으로 검색된다.</p>
</div>

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">LLM 출력 검증</span><span class="rs-metric">오류율 10% → 5% → 불일치 0/91</span></div>
<p class="rs-desc">연습문제 정답 인덱스 오류를 별도 모델 교차 채점으로 측정하고 프롬프트로 절반까지 줄인 뒤, 정답을 번호·값으로 중복 출력시켜 코드가 내부 일관성을 검사하고 어긋나면 재생성하는 런타임 가드를 도입.</p>
</div>

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">성능 최적화</span><span class="rs-metric">응답 68s → 37s</span></div>
<p class="rs-desc">외부 API 6회 동기 호출을 병렬 처리하고, 프롬프트 경량화와 SSE 스트리밍을 더해 체감 지연을 줄임.</p>
</div>

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">조건 분기 파이프라인 (LangGraph)</span><span class="rs-metric">웹검색 생략 · 무관 기록 차단</span></div>
<p class="rs-desc">라우터가 질문별로 웹검색 생략과 무관 기록 차단을 판단하는 에이전트 그래프로 직선 파이프라인을 전환. 기존 서비스 메서드를 노드로 재사용했다.</p>
</div>

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">비동기 환각 방어</span><span class="rs-metric">답변 속도 미차단</span></div>
<p class="rs-desc">생성과 다른 계열 모델로 근거 자료와의 모순을 비동기 검증하고, 결과를 출처 배지로 표시.</p>
</div>

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">테스트 · 배포 자동화</span><span class="rs-metric">테스트 73개 · CI</span></div>
<p class="rs-desc">pytest + factory_boy 테스트와 GitHub Actions CI, dbpush/dbpull DB 동기화 커맨드와 주간 자동 백업, Docker Compose·Render 배포.</p>
</div>

</div>

---

## 잇다루프 — AI 식품 순환 플랫폼 (2026.08, 팀 5인 / AI 부트캠프 해커톤)

[배포 사이트](https://eatda-roop.onrender.com/) | [아키텍처 합의 문서](https://claude.ai/code/artifact/e8b4d675-3960-49d0-85e2-ff3d3dd89783)

날씨·유동인구·판매 이력으로 메뉴별 수요를 예측해 권장 조리량을 산출하고, 예상 잉여 식재료를 공식 푸드뱅크와 매칭하는 서비스

### 기술 스택
Django / pandas / LightGBM / Figma / Render

### 역할 — 기획 · 화면 설계 · 웹 백엔드 (팀 내 유일 웹 개발자)

- **착수 전 아키텍처 합의**: 5인이 함께 읽는 아키텍처 문서를 작성해 Django 앱 경계를 담당자 경계와 일치시키고, 파트 간 함수 계약 3건(입출력 규격)을 먼저 확정. 각자 가짜 함수·가짜 데이터로 먼저 시작하게 해 **파트 간 대기 시간을 없앰**
- **범위 확정**: 만들 것과 만들지 않을 것을 문서에 명시하고, 웹 인력 1명 기준으로 아이디어톤 9개 화면을 4개 페이지로 통합해 핵심 흐름이 동작하는 MVP로 확정
- **데이터 신뢰성 기준 제시**: 판매 데이터가 합성값임을 발표에서 명시하도록 하고, 평가 기준을 "예측 정확도"가 아닌 **시간 순서 검증(데이터 누수 차단)과 베이스라인 대비**로 합의
- **Django 통합·배포**: 입력 화면·예측 실행·결과 화면 구성, 데이터 파트 함수 연결, 학습/서빙 분리(모델은 앱 시작 시 1회 로드), 예외 처리와 Render 배포. 데이터 형식이 자주 바뀌는 단계라 DB 대신 JSON 파일로 관리하고, 시연 중 변경분과 시드를 분리해 재시작 시 초기 상태로 복원되게 구성
- **기획·화면 설계**: 요구사항 정의, 데이터 출처·한계 정리, Figma MVP 화면 설계

---

# 학력

## 충북대학교 (2016 ~ 2020)

정보통신공학과

## 멋쟁이사자처럼 (2019 ~ 2020)

Django 웹개발 대외활동 운영진
