# 학습로그 검색 기능 - Full-Text Search 구현

[https://github.com/aengu/learn-log/commit/1f98694b87a686b905ddcb3c5f258d8b485e6d66](https://github.com/aengu/learn-log/commit/1f98694b87a686b905ddcb3c5f258d8b485e6d66)

| **항목** | **내용** |
| --- | --- |
| 목적 | 학습로그 리스트에서 `query`, `ai_response` 필드를 대상으로 키워드 검색 |
| 방식 | PostgreSQL Full-Text Search (`SearchVector`, `SearchQuery`, `SearchRank`) |
| 정렬 | 검색 시 연관도순 기본, 비검색 시 최신순/오래된순/조회수순 |

---

## **요구사항**

- query(질문)와 ai_response(AI 답변) 필드에서 키워드를 검색한다
- 검색 결과는 연관도(relevance) 순으로 정렬한다
- query 필드 매칭에 더 높은 가중치를 부여한다
- 검색과 정렬(최신순/오래된순/조회수순)을 동시에 사용할 수 있다
- 무한스크롤 시 검색어와 정렬 상태를 유지한다

---

## **PostgreSQL Full-Text Search로 선택한 이유**

icontains(LIKE 검색)와 Full-Text Search 비교:

```sql
- icontains 방식 (Django의 __icontains)
SELECT  FROM search_learninglog
WHERE query LIKE '%Django 설정%' OR ai_response LIKE '%Django 설정%';

- Full-Text Search 방식
SELECT , ts_rank( setweight(to_tsvector('simple', query), 'A') || 
setweight(to_tsvector('simple', ai_response), 'B'), 
to_tsquery('simple', 'Django & 설정')) AS rank
FROM search_learninglog
WHERE ( setweight(to_tsvector('simple', query), 'A') || 
setweight(to_tsvector('simple', ai_response), 'B')
) @@ to_tsquery('simple', 'Django & 설정')
ORDER BY rank DESC;
```

|  | **icontains (LIKE)** | **Full-Text Search** |
| --- | --- | --- |
| 매칭 방식 | 문자열 포함 여부 (연속 일치) | 토큰 단위 매칭 (단어가 떨어져 있어도 매칭) |
| "Django 설정" 검색 | "Django 설정"이 연속으로 있어야 매칭 | "설정"과 "Django"가 따로 있어도 매칭 |
| 결과 정렬 | 매칭 여부만 (O/X), 정렬 불가 | `ts_rank`로 연관도 점수 계산 → 순위 정렬 |
| 필드별 가중치 | 불가 | `setweight`로 A~D 가중치 부여 가능 |
| 성능 | 테이블 풀스캔 (`LIKE '%..%'`는 인덱스 사용 불가) | GIN 인덱스로 빠른 검색 가능 |

이 프로젝트에서 Full-Text Search를 선택한 이유:

1. 이미 PostgreSQL을 사용 중이므로 추가 설치 없이 바로 사용 가능
2. query 필드에 검색어가 있으면 ai_response에만 있는 것보다 더 관련 있는 결과 → **가중치 필요**
3. 검색 결과를 연관도순으로 정렬해야 함 → icontains로는 불가

### **Full-Text Search 핵심 개념**

**1. `to_tsvector` — 텍스트를 검색 가능한 토큰으로 변환**

```sql
SELECT to_tsvector('simple', 'Django REST Framework 설정 방법');
-- 결과: 'django':1 'rest':2 'framework':3 '설정':4 '방법':5
```

문장을 단어(토큰)로 쪼개고 정규화한다. `config='simple'`은 언어별 어간 추출 없이 공백 기준 토큰화.

**2. `to_tsquery` — 검색어도 같은 방식으로 변환**

```sql
SELECT to_tsquery('simple', 'Django & 설정');
-- 결과: 'django' & '설정'
```

**3. `@@` 연산자 — PostgreSQL 전용, tsvector와 tsquery 매칭 확인**

```sql
SELECT to_tsvector('simple', 'Django REST 설정') 
@@ to_tsquery('simple', 'Django & 설정');
-- 결과: true
```

**4. `setweight` + `ts_rank` — 필드별 가중치와 연관도 점수**

```python
setweight(to_tsvector('simple', query), 'A')       -- weight A = 1.0
setweight(to_tsvector('simple', ai_response), 'B')  -- weight B = 0.4
```

"Django"가 query에 있으면 1.0점, ai_response에만 있으면 0.4점.

## **구현**

### **검색 + 정렬 통합 메서드 (models.py)**

```python
from django.contrib.postgres.search import SearchVector, SearchQuery, SearchRank

class LearningLog(models.Model):
    # ...

    @classmethod
    def get_queryset(cls, q='', sort='latest'):
        base = cls.objects.prefetch_related('tags')

        if q:
            vector = (
                SearchVector('query', weight='A', config='simple') +
                SearchVector('ai_response', weight='B', config='simple')
            )
            query = SearchQuery(q, config='simple')
            base = base.annotate(rank=SearchRank(vector, query)).filter(rank__gt=0)

        if sort == 'relevance' and q:
            return base.order_by('-rank')
        elif sort == 'views':
            return base.order_by('-view_count', '-created_at')
        elif sort == 'oldest':
            return base.order_by('created_at')
        return base.order_by('-created_at')
```

Django ORM이 생성하는 실제 SQL:

```python
- LearningLog.get_queryset(q='Django', sort='relevance') 호출 시

SELECT , ts_rank( setweight(to_tsvector('simple', query), 'A') 
|| setweight(to_tsvector('simple', ai_response), 'B'), 
to_tsquery('simple', 'Django') ) AS rank
FROM search_learninglog
WHERE ( setweight(to_tsvector('simple', query), 'A') || 
setweight(to_tsvector('simple', ai_response), 'B')) 
@@ to_tsquery('simple', 'Django') AND rank > 0
ORDER BY rank DESC;
```

검색과 정렬을 하나의 메서드로 통합한 이유:

- 검색 결과(`rank > 0`으로 필터된 queryset)에 정렬을 체이닝할 수 있어야 함
- 기존에 `get_sorted_queryset()`과 `search()`를 분리했더니 검색 + 정렬 동시 사용이 불가했음
- `get_queryset(q='Django', sort='views')` 한 번 호출로 **검색 필터 + 정렬**을 동시 처리

**왜 Model classmethod인가**

| **위치** | **장단점** |
| --- | --- |
| **Model classmethod (현재)** | `LogListView`, `LogListAPIView` 두 곳에서 한 줄로 호출. 로직 중복 없음 |
| View에서 직접 | 두 뷰에 동일한 검색/정렬 코드 중복 |
| DRF ViewSet + FilterBackend | `SearchFilter`, `OrderingFilter`는 **JSON 응답** 전용. HTMX의 HTML 조각 반환 구조에서는 사용 불가 |
| DRF Serializer | 데이터 직렬화/역직렬화 역할. 쿼리 필터링/정렬은 Serializer의 책임이 아님 |

이 프로젝트는 HTMX로 HTML 조각을 반환하는 구조이므로 DRF의 내장 Filter/Pagination을 쓸 수 없다. 두 뷰에서 동일한 쿼리 로직을 공유하기 위해 Model classmethod가 가장 적합하다고 생각했음.

### **뷰 호출부 (views.py, api_views.py)**

추후 중복된 코드 리팩토링 예정

```python
# LogListView, LogListAPIView 둘 다 동일한 패턴
q = request.GET.get('q', '').strip()
sort = request.GET.get('sort', 'relevance' if q else 'latest')
logs = LearningLog.get_queryset(q=q, sort=sort)
```

- 검색어가 있으면 기본 정렬을 relevance(연관도순)로 설정
- 검색어가 없으면 기본 정렬 latest(최신순)

### **검색 UI (list.html)**

```html
<form action="" method="get" class="join">
    <input type="text" name="q" value="{{ search_query }}"
           placeholder="검색..."
           class="input input-bordered input-sm join-item w-48">
    <button type="submit" class="btn btn-sm join-item">검색</button>
</form>
{% if search_query %}
<a href="{% url 'search:log_list' %}" class="btn btn-ghost btn-sm">초기화</a>
{% else %}
<select class="select select-bordered select-sm" onchange="location.href='?sort=' + this.value">
    <option value="latest">최신순</option>
    <option value="oldest">오래된순</option>
    <option value="views">조회수순</option>
</select>
{% endif %}
```

- 검색 중에는 정렬 셀렉트를 숨기고 **초기화 버튼** 표시 (연관도순 고정)
- 검색하지 않을 때만 정렬 옵션 표시

### **무한스크롤 연동 (log_cards.html, list.html)**

```html
<div hx-get="/api/logs/?page={{ next_page }}&sort={{ current_sort }}&q={{ search_query|urlencode }}"
     hx-trigger="revealed"
     hx-swap="outerHTML">
```

스크롤 시 `q`와 `sort` 파라미터를 함께 전달하여 검색/정렬 상태를 유지한다.

---

## **앞으로의 개선 예정**

**GIN 인덱스 추가 및 성능 비교 테스트**

현재는 GIN 인덱스 없이 동작한다. 매 검색마다 모든 행을 `to_tsvector` 변환하면서 풀스캔하므로 데이터가 많아지면 느려질 수 있다.

```python
# models.py - Meta.indexes에 추가 예정
from django.contrib.postgres.indexes import GinIndex
from django.contrib.postgres.search import SearchVector

indexes = [
    GinIndex(
        SearchVector('query', 'ai_response', config='simple'),
        name='idx_log_search',
    ),
]
```

개인 학습로그 규모에서는 당장 체감 차이가 없으므로, 데이터가 쌓인 후 실제 성능 차이를 측정하고 인덱스 추가를 결정할 예정.