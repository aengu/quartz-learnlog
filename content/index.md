# 신혜란

> Django 기반 백엔드 개발자입니다.
> 주식 자동매매 서비스를 초기부터 운영까지 담당하며 서비스 분리, DB 부하 분산, 스케줄러 설계 등 실서비스 운영 경험이 있습니다.
> 이후 실무에서 아쉬웠던 쿼리 최적화(N+1 문제, QuerySet 평가 시점)와 DB Lock 등을 깊이 학습하며 기반을 다졌고, 최근에는 AI API를 활용한 개인 프로젝트를 통해 테스트 자동화, CI/CD, 컨테이너 기반 개발 환경까지 직접 구축하고 있습니다.

---

# Contact

- Email: shr19970923@gmail.com
- GitHub: [https://github.com/aengu](https://github.com/aengu)

---

# Skills

| 분류 | 기술 |
| --- | --- |
| Backend | Python, Django, Django REST Framework |
| Database | PostgreSQL (Full-Text Search), MySQL |
| Infra | Docker, Docker Compose, AWS (EC2, ELB, Auto Scaling, RDS) |
| CI/CD | GitHub Actions, pytest, factory_boy |
| AI/API | Groq API (Llama 3.3), Tavily API |
| etc | Git, Jira, Confluence |

---

# 경력

## 주식회사 맥클로린 (2021.03 ~ 2022.08)

**큐앤에이소프트** — 퀀트 딥러닝 주식 자동매매 서비스 개발 및 운영

서비스 초기부터 참여하여, 주문 시스템 개발과 인프라 안정화를 담당했습니다.
→ [[큐앤에이소프트- 상세페이지]]

### 주문 시스템 개발
- 이베스트/키움 증권 API를 활용한 자동매매 시스템 구현
- [주문 생성 → 승인 → 체결 → 완료] 구조에 승인 시스템을 도입하여 그룹/고객별 모니터링 체계 구축
- 주차별 비중 조정, 종목 리밸런싱, 승인 요청 알림 등 트랜잭션을 APScheduler로 관리

### 서비스 분리 및 부하 분산
- **문제**: 리밸런싱 시 시스템 전체가 느려지는 현상 발생
- **1차 해결**: 사내포털과 주문처리 서버를 Django 프로젝트 단위로 분리
- **2차 해결**: 주문처리 서버에 ELB + Auto Scaling 적용 — CPU 사용량 기준으로 인스턴스 자동 확장
- **3차 해결**: 주문처리 DB를 별도 분리하고, 사내포털에서 Django DB Router로 두 DB를 동시에 조회할 수 있도록 구성

### 스케줄러 분리
- **문제**: Gunicorn worker마다 APScheduler가 중복 실행되는 현상 발견
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

---

# 프로젝트

## LearnLog — AI 개발 지식 베이스 (2025)

[GitHub](https://github.com/aengu/learn-log) | [배포 사이트](https://learn-log.onrender.com/) | [[📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템|포트폴리오]]

개발 중 기술적 질문을 검색하면 AI가 답변과 공식 레퍼런스를 자동으로 찾아 마크다운으로 정리해주는 아카이브 시스템

### 기술 스택
Django 5 / DRF / PostgreSQL / Docker / HTMX / Tailwind CSS / pytest / GitHub Actions / Render

### 주요 구현

- **AI 답변 + 레퍼런스 통합**: Tavily API로 공식 문서 검색 → Groq API(Llama 3.3)로 답변 생성 → 노션 스타일 마크다운으로 변환
- **SSE 스트리밍**: StreamingHttpResponse로 검색 진행 상태를 실시간 전달 (프로그레스바 + 진행 로그)
- **Full-Text Search**: PostgreSQL SearchVector/SearchRank 기반 한국어 검색 구현
- **간격 반복 연습문제 시스템**: 학습 로그 기반으로 3가지 유형의 연습문제를 LLM이 자동 생성하고 채점. 간격 반복 알고리즘(1, 3, 7, 14, 30일)으로 복습 스케줄 관리
- **LLM 출력 검증**: correct_index 오류를 발견하고 프롬프트 수정 → N=20 비교 테스트로 오류율 20% → 0% 감소 확인
- **DB 동기화/백업**: Django management command(dbpush/dbpull)로 로컬-Render DB 동기화, GitHub Actions로 주간 자동 백업
- **테스트 자동화**: pytest + factory_boy 기반 테스트, GitHub Actions CI

---

# 학력

## 충북대학교 (2016 ~ 2020)

정보통신공학과

## 멋쟁이사자처럼 (2019 ~ 2020)

Django 웹개발 대외활동 운영진
