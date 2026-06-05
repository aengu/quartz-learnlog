# 신혜란

> - Django 기반 백엔드 개발자
> - 주식 자동매매 서비스 초기~운영 담당 (주문 승인 시스템·스케줄러 분리·DB 커넥션 관리 직접 개발 / 후반 단독 운영)
> - 공백기 중 DB 심화 학습 — ORM 최적화, 트랜잭션, MVCC 등 [12편 포스팅 공개](https://aengu.github.io/quartz-learnlog/이력서/신혜란/What-I-Learned/)
> - AI API 활용 개인 프로젝트([LearnLog](https://aengu.github.io/quartz-learnlog/)) — LLM 6종 활용, 프롬프트 검증 체계 구축, Docker/CI/CD 직접 설계

## About me

주식 자동매매 서비스를 서비스 초기부터 약 1.5년간 개발·운영했습니다. 부하 분산 과정에서 스케줄러 분리·DB 커넥션 관리를 직접 담당했고, 주문 승인 시스템을 설계·구현했습니다. 후반 약 7개월은 단독으로 운영을 맡았습니다. 공백기 동안에는 실무에서 부족했던 DB 심화 영역을 [12편의 기술블로그](https://aengu.github.io/quartz-learnlog/이력서/신혜란/What-I-Learned/)로 정리했고, AI API를 활용한 개인 프로젝트([LearnLog](https://aengu.github.io/quartz-learnlog/))를 설계부터 배포·테스트 자동화까지 직접 구축했습니다. 개선한 것은 수치로 확인하고, 학습한 것은 글로 남기는 습관을 유지하고 있습니다.

---

# Contact

- Email: shr19970923@gmail.com
- GitHub: [https://github.com/aengu](https://github.com/aengu)
- Tech Notes: [https://aengu.github.io/quartz-learnlog/](https://aengu.github.io/quartz-learnlog/)

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

**큐앤에이소프트** — 퀀트 딥러닝 주식 자동매매 서비스 개발 및 운영

서비스 초기부터 참여하여, 주문 시스템 개발과 인프라 안정화를 담당했습니다.
활성 고객 600+명, 월간 리밸런싱 시 약 18만~27만 건의 주문을 처리했습니다.
→ [[큐앤에이소프트- 상세페이지]]

### 주문 시스템 개발
- 이베스트/키움 증권 API 연동 자동매매 시스템 개발 참여
- [주문 생성 → 승인 → 체결 → 완료] 구조에 승인 시스템을 도입하여 그룹/고객별 모니터링 체계 구축
- 주차별 비중 조정, 종목 리밸런싱, 승인 요청 알림 등 트랜잭션을 APScheduler로 관리
- **주문 중복 집행 방지 (동시성 제어)**: 승인된 주문을 집행 주문으로 변환하는 트랜잭션에서 `select_for_update`로 행을 잠그고 상태값(`is_progress`)으로 선점해, 동시 실행 환경에서 동일 주문의 중복 집행을 차단 (`select_related`로 연관 조회 최적화)
- **대량 주문 처리**: 월 리밸런싱 시 18만~27만 건의 주문을 `bulk_create`/`bulk_update`로 일괄 처리하여 DB 왕복 최소화. 계좌·포트폴리오 동기화는 전량 삭제·재삽입 대신 집합 연산 기반 diff(교집합→update / 차집합→delete·insert)로 불필요한 쓰기 감소

### 부하 분산
- 리밸런싱 시 시스템 전체가 느려지는 문제를, 팀에서 서비스를 Django 프로젝트 단위로 분리하고 ELB + Auto Scaling 적용 + 주문 DB 분리 후 DB Router로 두 DB를 동시 조회하도록 구성해 해결 (상시 고사양 대비 월 서버 비용 약 400만 → 200~300만 원 절감)

### 스케줄러 분리
- **문제**: Gunicorn worker 4개마다 APScheduler가 중복 실행되어 같은 작업이 4회씩 실행되는 현상 발견
- **해결**: 스케줄러를 별도 Django 프로젝트로 분리하여 단일 프로세스로 실행

### DB Connection 관리
- **문제**: 주문 DB가 8~17시만 active인데, 스케줄러 스레드가 connection을 유지하여 DB 재시작 후에도 lost connection 에러 지속
- **해결**: 스케줄러 트랜잭션 종료 시 connection을 명시적으로 close하도록 수정

### 기타
- CRM 권한 관리 — 팀/직급별 기능 제한을 Django admin에서 관리 가능하도록 구현
- 영업팀 녹취파일 일별 통화시간 집계 자동화 (오디오파일 ETL)

---

## 연세대학교 LandFlow 프로젝트 (2021.07 ~ 2021.11)

토석류 유동 시뮬레이션 프로그램 — Matlab GUI(App Designer) 개발
→ [[landflow- 상세페이지]]

- 2차원 지형 이미지 위에 등고선을 오버레이하고, brush 기능으로 영역 선택 후 값을 삽입하는 인터페이스 구현
- brush를 지원하지 않는 heatmap 대신 surf 함수를 활용하여 3D 데이터를 2D 시점으로 표현하는 방식으로 해결

![[신혜란/최초실행영상.gif]]

---

# 프로젝트

## LearnLog — AI 개발 지식 베이스 (2026)

[GitHub](https://github.com/aengu/learn-log) | [배포 사이트](https://learn-log.onrender.com/) | [[📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템|포트폴리오]]

개발 중 기술적 질문을 검색하면 AI가 답변과 공식 레퍼런스를 자동으로 찾아 마크다운으로 정리해주는 아카이브 시스템

### 기술 스택
Django 5 / DRF / PostgreSQL / Docker / HTMX / Tailwind CSS / pytest / GitHub Actions / Render

### 주요 구현

- **AI 답변 + 레퍼런스 통합**: Tavily API로 공식 문서 검색 → Mistral Large로 답변 생성 → Groq(Llama 3.3)로 태그 추출/마크다운 변환
- **SSE 스트리밍**: StreamingHttpResponse로 검색 진행 상태를 실시간 전달 (프로그레스바 + 진행 로그)
- **Full-Text Search**: PostgreSQL SearchVector/SearchRank 기반 한국어 검색 구현
- **간격 반복 연습문제 시스템**: 저장한 학습 로그를 정말 이해했는지 점검하기 위한 연습문제. 학습 로그 기반으로 LLM이 두 유형(직접 답하기 / 선택지 고르기)으로 출제 → 간격 반복 알고리즘(1, 3, 7, 14, 30일)으로 복습 스케줄 관리
- **LLM 출력 검증**: correct_index 오류를 발견하고 프롬프트 수정 → LLM Judge 검증 체계 구축으로 오류율 10% → 5% 감소 확인
- **DB 동기화/백업**: Django management command(dbpush/dbpull)로 로컬-Render DB 동기화, GitHub Actions로 주간 자동 백업
- **테스트 자동화**: pytest + factory_boy 기반 테스트, GitHub Actions CI

---

# 학력

## 충북대학교 (2016 ~ 2020)

정보통신공학과

## 멋쟁이사자처럼 (2019 ~ 2020)

Django 웹개발 대외활동 운영진
