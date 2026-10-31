# 신혜란

> **Python/Django 백엔드 개발자 — 금융 주문 시스템 운영 · LLM/RAG 서비스 개발**
>
> - 활성 고객 수백 명 규모·월 20만 건대 주문을 처리하는 주식 자동매매 서비스 개발·운영 — 주문 승인 시스템 설계, 동시성 제어·스케줄러 중복 실행·DB 커넥션 문제 해결, 후반 7개월 단독 운영
> - AI API 활용 개인 프로젝트(LearnLog) — 하이브리드 검색(RAG)·LLM 출력 검증·CI 품질 검사·BKT 기반 개념별 숙련도 추적 설계·구현
> - Django·DB 핵심 주제(ORM 최적화·트랜잭션·MVCC 등)를 학습하고, 개념 정리와 직접 실험을 병행해 [기술 글 13편으로 정리](https://aengu.github.io/quartz-learnlog/이력서/신혜란/What-I-Learned/)
> - AI 부트캠프 5인 팀 해커톤 — 수요예측 기반 식품 순환 플랫폼(잇다루프) 기획·화면 설계·백엔드 담당, 파트 간 함수 계약을 먼저 확정해 대기 없이 병렬 개발

---

# Contact

- Email: shr19970923@gmail.com
- GitHub: [https://github.com/aengu](https://github.com/aengu)
- Tech Notes: [https://aengu.github.io/quartz-learnlog/](https://aengu.github.io/quartz-learnlog/)
- 자기소개서: [[자기소개서]]

---

# 경력

## 주식회사 맥클로린 (2021.03 ~ 2022.08)

**큐앤에이소프트**(맥클로린 소속 사내 회사) — 퀀트 딥러닝 주식 자동매매 서비스 개발 및 운영

서비스 초기부터 참여하여 주문 시스템 개발과 운영 안정화를 담당했고, 후반 약 7개월은 단독으로 운영했습니다.
활성 고객 수백 명 규모 / 월 리밸런싱 시 20만 건대 주문 처리.
→ [[큐앤에이소프트- 상세페이지]]

### 주문 시스템
- **주문 중복 집행 방지 (동시성 제어)**: 승인 주문을 집행으로 변환할 때 `select_for_update` 행 잠금 + 상태값 선점으로, 작업이 동시에 도는 환경에서 같은 주문의 이중 집행(= 고객 자산 이중 매매)을 차단
- **주문 승인 시스템 설계·도입**: 고객 사전 승인을 받아야 하는 규정에 맞춰 [생성 → 승인 → 체결 → 완료] 단계를 도입 → 리밸런싱 대량 주문의 오발주(휴먼 에러)를 사전 차단하고 그룹/고객별 모니터링 가능
- 월 20만 건대 대량 주문을 `bulk_create`/`bulk_update`로 일괄 처리해 DB 왕복 최소화

### 운영 안정화
- 리밸런싱 부하로 서비스가 느려져 **팀이 서비스·DB를 분리**(AWS ELB·Auto Scaling·DB Router, 상시 고사양 대비 월 서버 비용 25~50% 절감)했고, 그 분리로 새로 생긴 두 가지 안정성 문제를 직접 해결했습니다:
    - **스케줄러 중복 실행**: 배포 시 워커마다 스케줄러가 떠 같은 작업이 4회씩 실행되던 문제를, 별도 프로세스로 분리해 제거
    - **DB 커넥션 오류**: 비용 절감을 위해 거래 시간대(8~17시)에만 켜두던 주문 MySQL이 그 외 시간에 닫히며 반복되던 lost connection을, 트랜잭션 종료 시 커넥션을 명시적으로 정리해 해소

### 기타
- 영업팀 상담 녹취 통화시간 자동 집계(ETL)로 매체별 상담 품질 측정 기반 마련

---

## 연세대학교 LandFlow 프로젝트 (2021.07 ~ 2021.11, 재직사 산학협력)

토석류 유동 시뮬레이션 Matlab GUI(App Designer) 개발 — 비개발 기획자와 협업해 요구사항을 화면으로 구체화
→ [[landflow- 상세페이지]]

---

# 프로젝트

## LearnLog — 질문을 기록하고 문제로 복습하는 AI 학습 서비스 (2026)

[GitHub](https://github.com/aengu/learn-log) | [배포 사이트](https://learn-log.onrender.com/) | [[📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템|포트폴리오]]

개발 질문·답변을 저장하고 생성된 문제로 복습하는 개인 학습 서비스. 개념별 이해도를 추적하고, 내 수준에 맞춰 같은 문제를 푸는 AI 러닝메이트를 구현했습니다.

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

### 기술 스택

<div class="rs-stack">
<span class="rs-chip" data-k="1">Django 5</span><span class="rs-chip" data-k="1">DRF</span><span class="rs-chip" data-k="1">PostgreSQL (FTS + pgvector)</span><span class="rs-chip" data-k="1">LangGraph</span><span class="rs-chip">Mistral</span><span class="rs-chip">Groq</span><span class="rs-chip">Tavily</span><span class="rs-chip" data-k="1">Docker</span><span class="rs-chip">pytest · pytest-cov</span><span class="rs-chip">Ruff</span><span class="rs-chip">GitHub Actions</span>
</div>

### 주요 구현

<div class="rs-impl">

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">학습기록 재활용 · 질문별 라우팅</span><span class="rs-metric">FTS + pgvector · LangGraph</span></div>
<p class="rs-desc">키워드·의미 검색 결과를 RRF로 결합하고, 라우터가 기록 활용·웹검색 필요 여부와 설명 방식을 판단하도록 LangGraph 파이프라인 구성. 별도 벡터 DB 없이 PostgreSQL에서 구현.</p>
</div>

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">답변 신뢰성 관리</span><span class="rs-metric">근거 기반 생성 · 비동기 모순 검사</span></div>
<p class="rs-desc">검색 자료를 참고해 답변을 생성하고, 저장 후 생성 모델과 다른 LLM으로 근거와의 모순을 검사. 검사 상태·의심 사유 표시와 복습 전 경고로 오답 재사용 위험을 관리하고, 검사는 스트리밍 응답과 분리.</p>
</div>

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">성능 최적화</span><span class="rs-metric">답변 생성 52.6s → 37.3s</span></div>
<p class="rs-desc">독립 후처리를 병렬화해 2.89s→1.01s로 단축. 프롬프트 경량화 전후 생성 시간 약 29% 감소를 관측하고, SSE로 생성 중 답변을 전달. 생성 시간은 당시 Mistral Large·단일 질문·2라운드 평균으로, 출력 길이 영향과는 미분리.</p>
</div>

<div class="rs-item">
<div class="rs-head b"><span class="rs-name">복습 상태 추적 · CI 품질 검사</span><span class="rs-metric">BKT · 서비스 커버리지 20% → 84%</span></div>
<p class="rs-desc">고정 파라미터 BKT로 승인된 문항의 정오답에서 개념별 숙련도를 갱신하고 러닝메이트 수준에 반영. 관측 이력·중복 반영 방지·시간순 재계산 구현.</p>
<p class="rs-desc">핵심 로직 테스트 보강으로 당시 연습문제 서비스 커버리지 20%→84%. GitHub Actions에 Ruff·pytest-cov·리포트를 연결하고, 실제 외부 API 예약 헬스체크는 분리.</p>
</div>

</div>

---

## 잇다루프 — 식품 수요예측·잉여 식재료 매칭 (2026.08, 5인 해커톤)

[배포 사이트](https://eatda-roop.onrender.com/)

- 기획·화면 설계와 Django 웹 백엔드 담당. 팀원이 만든 수요예측 함수를 연결하고 입력·결과 화면 구현 및 Render 배포.
- 사용 기술: Django · Figma · Render

---

# 학력

## 충북대학교 (2016 ~ 2020)

정보통신공학과

## 멋쟁이사자처럼 (2019 ~ 2020)

Django 웹개발 대외활동 운영진
