# 📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템

[https://github.com/aengu/learn-log](https://github.com/aengu/learn-log)

[Learn Log - AI 개발 지식 베이스](https://learn-log.onrender.com/)

## 🎯 프로젝트 개요

개발 중 구글링하듯 기술적 질문을 검색하면, AI가 답변과 함께 공식 레퍼런스를 자동으로 찾아주고, 이를 노션 형식의 마크다운으로 정리해 아카이빙하는 시스템입니다.

**핵심 가치**: 개발자의 학습 과정을 체계적으로 기록하고, 언제든 다시 찾아볼 수 있는 개인 지식 베이스 구축

---

## ✨ 주요 기능

### 1. **AI 기반 기술 질문 답변**

- 사용자가 입력한 개발 관련 질문에 대해 AI가 상세한 답변 제공
- 예: "docker bridge network와 host network 차이"

### 2. **공식 레퍼런스 자동 검색 및 발췌**

- 질문과 관련된 공식 문서 자동 검색
- 각 레퍼런스의 URL 및 핵심 내용 발췌

### 3. **노션 스타일 마크다운 자동 변환**

- AI 답변과 레퍼런스를 하나의 문서로 통합
- 표(table), 코드 블록, 하이라이트 등이 포함된 읽기 쉬운 포맷
- 노션에 바로 복사/붙여넣기 가능

### 4. **검색 히스토리 아카이빙**

- 모든 검색 내용을 게시판 형식으로 저장
- 태그/카테고리별 분류
- 검색 및 필터링 기능

---

## 🛠 기술 스택

### **Backend**

- **Django 5.x**: 웹 프레임워크
- **Django REST Framework**: API 엔드포인트 구현
- **PostgreSQL**: 검색 히스토리 및 메타데이터 저장, Full-Text Search

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

## 🤖 AI/검색 LLM API

### **1. Tavily API** (웹 검색)

- **역할**: 실시간 웹 검색 및 공식 레퍼런스 발견
- **장점**:
    - AI 에이전트에 최적화된 검색 엔진
    - 무료 티어 제공
    - 특정 도메인(공식 문서) 우선 검색 가능
- **사용 사례**:
    - 질문 관련 공식 문서 URL 수집
    - 각 문서의 핵심 내용 발췌

### **2. Groq API** (LLM)

- **역할**: AI 답변 생성 및 마크다운 변환
- **모델**: Llama 3.3 70B Versatile
- **장점**:
    - 무료 티어 (하루 14,400 요청)
    - 초고속 응답 속도
    - 코드/기술 질문에 강함
- **사용 사례**:
    - 기술 질문에 대한 상세한 답변 생성
    - Tavily 검색 결과를 통합하여 노션 스타일 마크다운 생성

## 개발일지

- [[vscode에서 Docker 컨테이너 디버깅하기]]
- [[Django 모델 설계 및 마이그레이션 초기화]]
- [[서비스 모델 설계]]
- [[학습 로그 서비스 계층 설계 및 구현]]
- [[기술 스택별 검색 도메인 자동 매핑 및 출처 판단 개선]]
- [[검색 중 프로그레스바 + 진행로그를 위한 SSE 구현]]
- [[학습로그 검색 기능 - Full-Text Search 구현]]
- [[GitHub Actions로 테스트자동화]]
- [[테스트코드 작성 - log list]]
- [[Render 무료 배포 + DB 동기화 + 자동 백업 구현]]
- [[render 배포웹 슬립 방지]]
- [[학습 로그 기반 간격 반복 연습문제 시스템 구현]]
- [[프롬프트 변경 효과 측정 - correct_index 오류율 비교 테스트]]