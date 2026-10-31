# 신혜란

> **Python/Django 백엔드 개발자**
>
> 활성 고객 수백 명·월 20만 건대 주문을 처리하는 주식 자동매매 서비스를 개발·운영했으며, 후반 약 7개월은 단독 운영했습니다. 현재는 AI 학습 서비스 LearnLog를 직접 만들고 사용하며 개선하고 있습니다.

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
<svg class="flow" viewBox="0 0 1600 410" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="LearnLog 사용 예시. DB 잠금이 무엇인지 질문하고 답변을 저장합니다. 저장한 답변으로 만든 복습 문제를 풉니다. 같은 문제를 푼 사용자와 AI 러닝메이트의 정오답을 비교합니다. 러닝메이트는 내 수준에 맞춰 같은 문제를 푸는 AI 파트너입니다.">
<rect width="1600" height="410" rx="16" fill="#F5F5F5"/>
<text x="24" y="43" fill="#315EAE" style="fill:#315EAE" font-family="Inter, Pretendard, Arial, sans-serif" font-size="27" font-weight="700">1. 질문한다</text>
<rect x="24" y="70" width="480" height="274" rx="10" fill="#FFFFFF" stroke="#D0D5DD"/>
<rect x="25" y="71" width="478" height="44" rx="10" fill="#101828"/>
<text x="46" y="100" fill="#FFFFFF" style="fill:#FFFFFF" font-family="Inter, Pretendard, Arial, sans-serif" font-size="20" font-weight="700">LearnLog</text>
<path d="M 510 207 H 553 M 543 201 L 553 207 L 543 213" fill="none" stroke="#98A2B3" stroke-width="2"/>
<text x="560" y="43" fill="#6941C6" style="fill:#6941C6" font-family="Inter, Pretendard, Arial, sans-serif" font-size="27" font-weight="700">2. 문제를 푼다</text>
<rect x="560" y="70" width="480" height="274" rx="10" fill="#FFFFFF" stroke="#D0D5DD"/>
<rect x="561" y="71" width="478" height="44" rx="10" fill="#101828"/>
<text x="582" y="100" fill="#FFFFFF" style="fill:#FFFFFF" font-family="Inter, Pretendard, Arial, sans-serif" font-size="20" font-weight="700">LearnLog</text>
<path d="M 1046 207 H 1089 M 1079 201 L 1089 207 L 1079 213" fill="none" stroke="#98A2B3" stroke-width="2"/>
<text x="1096" y="43" fill="#087A5B" style="fill:#087A5B" font-family="Inter, Pretendard, Arial, sans-serif" font-size="27" font-weight="700">3. 결과를 비교한다</text>
<rect x="1096" y="70" width="480" height="274" rx="10" fill="#FFFFFF" stroke="#D0D5DD"/>
<rect x="1097" y="71" width="478" height="44" rx="10" fill="#101828"/>
<text x="1118" y="100" fill="#FFFFFF" style="fill:#FFFFFF" font-family="Inter, Pretendard, Arial, sans-serif" font-size="20" font-weight="700">LearnLog</text>
<text x="46" y="159" fill="#182230" style="fill:#182230" font-family="Inter, Pretendard, Arial, sans-serif" font-size="28" font-weight="700">DB 잠금이 뭐야?</text>
<text x="46" y="202" fill="#315EAE" style="fill:#315EAE" font-family="Inter, Pretendard, Arial, sans-serif" font-size="20" font-weight="700">AI 답변</text>
<text x="46" y="238" fill="#182230" style="fill:#182230" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23">여러 작업이 같은 데이터를 바꿀 때,</text>
<text x="46" y="272" fill="#182230" style="fill:#182230" font-family="Inter, Pretendard, Arial, sans-serif" font-size="23">충돌하지 않도록 접근을 조절해요.</text>
<rect x="46" y="293" width="436" height="33" rx="10" fill="#EAF1FF"/>
<text x="118" y="317" fill="#315EAE" style="fill:#315EAE" font-family="Inter, Pretendard, Arial, sans-serif" font-size="20" font-weight="700">답변을 학습 기록으로 저장</text>
<text x="582" y="159" fill="#182230" style="fill:#182230" font-family="Inter, Pretendard, Arial, sans-serif" font-size="26" font-weight="700">DB 잠금을 사용하는 이유는?</text>
<rect x="582" y="195" width="436" height="51" rx="10" fill="#F0EAFF"/>
<text x="600" y="229" fill="#6941C6" style="fill:#6941C6" font-family="Inter, Pretendard, Arial, sans-serif" font-size="22" font-weight="700">데이터 변경 충돌을 막으려고 ✓</text>
<rect x="582" y="262" width="436" height="51" rx="10" fill="#F5F5F5"/>
<text x="600" y="296" fill="#667085" style="fill:#667085" font-family="Inter, Pretendard, Arial, sans-serif" font-size="22">데이터를 더 작게 저장하려고</text>
<text x="1118" y="159" fill="#182230" style="fill:#182230" font-family="Inter, Pretendard, Arial, sans-serif" font-size="25" font-weight="700">같은 문제의 풀이 결과</text>
<text x="1118" y="217" fill="#182230" style="fill:#182230" font-family="Inter, Pretendard, Arial, sans-serif" font-size="24" font-weight="700">나</text>
<text x="1488" y="217" fill="#087A5B" style="fill:#087A5B" font-family="Inter, Pretendard, Arial, sans-serif" font-size="24" font-weight="700">정답</text>
<path d="M 1118 239 H 1554" stroke="#D0D5DD" fill="none"/>
<text x="1118" y="284" fill="#6941C6" style="fill:#6941C6" font-family="Inter, Pretendard, Arial, sans-serif" font-size="24" font-weight="700">AI 러닝메이트</text>
<text x="1488" y="284" fill="#B54708" style="fill:#B54708" font-family="Inter, Pretendard, Arial, sans-serif" font-size="24" font-weight="700">오답</text>
<text x="24" y="385" fill="#667085" style="fill:#667085" font-family="Inter, Pretendard, Arial, sans-serif" font-size="19">기능 설명용 목업 · 질문·보기·결과는 예시</text>
<text x="1096" y="375" fill="#6941C6" style="fill:#6941C6" font-family="Inter, Pretendard, Arial, sans-serif" font-size="21">내 수준에 맞춰 같은 문제를 푸는</text>
<text x="1096" y="403" fill="#6941C6" style="fill:#6941C6" font-family="Inter, Pretendard, Arial, sans-serif" font-size="21">AI 파트너</text>
</svg>
</div>

<div class="rs-stack-summary" style="break-inside:avoid;page-break-inside:avoid">
<h3>기술 스택</h3>
<ul>
<li><strong>Backend:</strong> Python · Django/DRF · PostgreSQL</li>
<li><strong>AI:</strong> LangGraph · RAG(FTS + pgvector)</li>
<li><strong>배포·품질:</strong> Docker · GitHub Actions · Ruff · CodeRabbit</li>
</ul>
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
