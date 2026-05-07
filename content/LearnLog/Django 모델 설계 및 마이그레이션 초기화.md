# Django 모델 설계 및 마이그레이션 초기화

[https://github.com/aengu/learn-log/commit/dd1d50e38328ffd06ce50a542c0794285f02b8f0](https://github.com/aengu/learn-log/commit/dd1d50e38328ffd06ce50a542c0794285f02b8f0)

| 항목 | 내용 |
| --- | --- |
| 목적 | LearnLog의 핵심 기능(AI 답변 아카이빙, 태그 분류, 레퍼런스 관리)을 구현하기 위한 모델 설계 |
| 범위 | Tag, Reference, LearningLog 모델 설계 + Docker 환경 마이그레이션 초기화 |

---

## 왜 이 구조인가

LearnLog의 핵심 흐름은 "질문 → AI 답변 + 레퍼런스 수집 → 마크다운 정리 → 아카이빙"이다. 이 흐름을 지원하려면 세 가지가 필요했다:

1. **학습 로그(LearningLog)**: 질문과 AI 답변, 마크다운 문서를 하나로 묶는 중심 모델
2. **태그(Tag)**: 학습 로그를 주제별로 분류하고, 태그 기반 검색/필터링을 가능하게
3. **레퍼런스(Reference)**: AI가 검색한 공식 문서 URL과 발췌 내용을 별도 모델로 관리 — 여러 학습 로그에서 같은 레퍼런스를 재사용할 수 있도록

태그와 레퍼런스 모두 처음에는 LearningLog 안에 ArrayField로 넣었다가, 태그별 통계나 레퍼런스 재사용이 필요해지면서 별도 모델 + ManyToMany 관계로 분리했다.

---

# 1. 모델 구조

### Tag (태그)

- 학습 로그 분류를 위한 태그
- 태그별 통계 및 검색 최적화

**주요 필드**

- `name`: 태그명 (unique)
- `slug`: URL 친화적 슬러그
- `created_at`: 생성일

---

### Reference (레퍼런스)

- 공식 문서 및 참고 자료 관리
- 여러 학습 로그에서 재사용 가능

**주요 필드**

- `url`: 문서 URL (unique)
- `title`: 문서 제목
- `excerpt`: 핵심 내용 발췌
- `source_type`: 출처 유형 (공식문서/블로그/Stack Overflow/GitHub/기타)
- `fetched_at`: 수집일

---

### LearningLog (학습 로그)

- AI 기반 질문-답변 기록
- 노션 스타일 마크다운 문서화

**주요 필드**

- `query`: 질문 내용
- `ai_response`: AI 답변
- `markdown_content`: 노션용 마크다운 통합 문서
- `references`: Reference와 M2M 관계
- `tags`: Tag와 M2M 관계
- `is_bookmarked`: 북마크 여부
- `view_count`: 조회수
- `created_at`: 생성일
- `updated_at`: 수정일

---

## 2. Docker 환경에서 마이그레이션 초기화

### 개발 초기라서 전체 초기화하는 방법

```bash
# 1. Docker 컨테이너 및 볼륨 삭제
docker-compose down -v

# 2. 마이그레이션 파일 삭제
rm -rf learning_logs/migrations/000*.py

# 3. Docker 재시작
docker-compose up -d

# 4. 새 마이그레이션 생성
docker-compose exec web python manage.py makemigrations

# 5. 마이그레이션 적용
docker-compose exec web python manage.py migrate

```

- `__pycache__` 폴더는 Python 바이트코드 캐시로, 삭제하지 않아도 무방
- 개발 초기에는 DB를 완전히 초기화하는 것이 가장 깔끔함
- `.gitignore`에 `__pycache__/`와 `.pyc` 추가 권장