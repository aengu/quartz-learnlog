# log list API 테스트 작성

[https://github.com/aengu/learn-log/commit/a3039ee670aaf25181489b6b4517d8c3cdd67535](https://github.com/aengu/learn-log/commit/a3039ee670aaf25181489b6b4517d8c3cdd67535)

| 항목 | 내용 |
| --- | --- |
| 목적 | API 테스트 자동화 환경 구축 (CI/CD + 로컬 디버깅) |
| 방식 | pytest-django + factory_boy + GitHub Actions |
| 범위 | LogListAPIView (필터/정렬/검색/페이지네이션), LogDetailAPIView (조회수/북마크) |

---

## Django TestCase에서 pytest + factory_boy로 전환한 이유

```python
# 기존 Django TestCase 방식

class LogTest(TestCase):
    def setUp(self):
        self.tag = Tag.objects.create(name='Django', slug='django')
        self.log = LearningLog.objects.create(
            query='Django란?',
            ai_response='웹 프레임워크입니다',
            markdown_content='# Django',
        )
        self.log.tags.add(self.tag)

    def test_filter_by_tag(self):
        response = self.client.get('/api/logs/', {'tag': 'django'})
        self.assertEqual(response.status_code, 200)
```

```python
# pytest + factory_boy 방식

pytestmark = pytest.mark.django_db

class TestLogListAPI:
    def test_filter_by_tag(self, client):
        tag = TagFactory(name="django", slug="django")
        LearningLogFactory(tags=[tag])
        resp = client.get(URL, {"tag": "django"})
        assert resp.status_code == 200
```

|  | Django TestCase | pytest + factory_boy |
| --- | --- | --- |
| 테스트 작성 | `class` + `self.assert*` | `function` + `assert` |
| 데이터 생성 | `setUp`에서 직접 `.create()` | Factory 한 줄 호출 |
| 재사용성 | 테스트 클래스마다 setUp 중복 | 팩토리 한 번 정의하면 전체에서 재사용 |
| M2M 관계 | `.create()` + `.add()` 수동 연결 | `LearningLogFactory(tags=[tag])` 한 줄 |
| fixture | `setUp()` 메서드 (클래스 단위) | `@pytest.fixture` (함수 단위, 조합 가능) |

전환 이유:

1. API가 늘어나면서 테스트마다 유사한 데이터 생성 코드가 반복됨 → factory_boy로 `LearningLogFactory()` 한 줄로 해결
2. `self.assertEqual(a, b)` 대신 `assert a == b`가 더 직관적
3. pytest fixture는 함수 단위로 주입되어 필요한 테스트에서만 사용 가능 (setUp은 클래스 내 모든 테스트에 적용)

---

## 테스트 패키지 구성

| 패키지 | 역할 |
| --- | --- |
| `pytest` | 테스트 실행기 (Django 기본 unittest 대체) |
| `pytest-django` | pytest에서 Django 프로젝트를 인식하고 실행할 수 있게 해주는 플러그인 |
| `factory-boy` | 테스트용 모델 데이터 생성 라이브러리 |

### pytest-django가 필요한 이유

pytest는 범용 Python 테스트 프레임워크라서 Django를 모른다. DB 연결, settings 로딩, 테스트 클라이언트 등 Django 고유 기능을 pytest에서 사용하려면 pytest-django가 필요하다.

pytest-django가 제공하는 것들

```python
# 1. DB 접근 허용 마커 — 이게 없으면 테스트에서 DB 접근 시 에러
pytestmark = pytest.mark.django_db

# 2. client fixture — Django 테스트 클라이언트를 자동 주입
def test_main_page(client):           # client를 인자로 받기만 하면 됨
    resp = client.get("/")

# 3. settings fixture — 테스트 중 Django settings 임시 변경
def test_debug_mode(settings):
    settings.DEBUG = True
```

### factory-boy가 필요한 이유

테스트마다 모델 데이터를 직접 생성하면 코드가 반복된다

```python
# factory-boy 없이 — 매 테스트마다 이런 코드가 반복
def test_filter_by_tag(client):
    tag = Tag.objects.create(name="django", slug="django")
    log = LearningLog.objects.create(
        query="Django란?",
        ai_response="웹 프레임워크입니다",
        markdown_content="# Django",
    )
    log.tags.add(tag)

def test_sort_by_views(client):
    log1 = LearningLog.objects.create(
        query="질문1",
        ai_response="답변1",
        markdown_content="# 1",
        view_count=1,
    )
    log2 = LearningLog.objects.create(
        query="질문2",
        ai_response="답변2",
        markdown_content="# 2",
        view_count=100,
    )
```

factory-boy를 쓰면

```python
# 팩토리 한 번 정의
class LearningLogFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = LearningLog
    query = factory.Sequence(lambda n: f"How does feature {n} work?")
    ai_response = "This is the AI response."
    markdown_content = "## Answer\nContent here."

# 사용 — 필요한 필드만 오버라이드
def test_filter_by_tag(client):
    tag = TagFactory(name="django", slug="django")
    LearningLogFactory(tags=[tag])

def test_sort_by_views(client):
    low = LearningLogFactory(view_count=1)
    high = LearningLogFactory(view_count=100)
```

`query`, `ai_response`, `markdown_content` 같은 필수 필드는 팩토리가 기본값을 채워주고, 테스트에서는 검증에 필요한 필드만 명시하면 된다.

---

## 테스트 실행 흐름

### 전체 구조

```
search/tests/
├── __init__.py
├── factories.py            # 모델별 팩토리 정의
├── conftest.py             # 공유 fixture (api_client 등)
├── test_pages.py           # 페이지 뷰 테스트
├── test_log_list_api.py    # LogListAPIView 테스트
└── test_log_detail_api.py  # LogDetailAPIView 테스트
```

### 테스트 실행 예시

```python
pytestmark = pytest.mark.django_db    # ① DB 사용 선언

class TestLogListAPI:
    def test_filter_by_tag(self, client):       # ② client fixture 주입
        tag = TagFactory(name="django", slug="django")  # ③ 테스트 DB에 태그 생성
        LearningLogFactory(tags=[tag])                   # ④ 태그 연결된 로그 생성
        LearningLogFactory()                             # ⑤ 태그 없는 로그 생성
        resp = client.get(URL, {"tag": "django"})        # ⑥ API 호출
        assert len(resp.context['logs'].object_list) == 1  # ⑦ 결과 검증
        # ⑧ 테스트 끝 → DB 자동 롤백 (다음 테스트에 영향 없음)
```

1. `pytest.mark.django_db` : pytest-django에게 이 테스트가 DB를 사용한다고 알림
2. `client` : pytest-django가 자동으로 Django 테스트 클라이언트를 생성하여 주입
3. `TagFactory()` : factory-boy가 Tag 모델 인스턴스를 테스트 DB에 생성
4. `LearningLogFactory(tags=[tag])` : LearningLog 생성 후 `@post_generation`으로 M2M 연결

 8. 각 테스트는 트랜잭션으로 감싸져 있어서 끝나면 자동 롤백됨 — 테스트 간 데이터 격리 보장

### 실행 명령어

```bash
# 로컬 Docker에서 전체 테스트
docker compose exec web pytest -v

# 특정 파일만
docker compose exec web pytest search/tests/test_log_list_api.py -v

# 특정 테스트만
docker compose exec web pytest search/tests/test_log_list_api.py::TestLogListAPI::test_filter_by_tag -v

```

---

### factory_boy 핵심 패턴

```python
class LearningLogFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = LearningLog

    query = factory.Sequence(lambda n: f"How does feature {n} work?")
    ai_response = "This is the AI response."
    markdown_content = "## Answer\nContent here."

    @factory.post_generation
    def tags(self, create, extracted, **kwargs):
        if not create or not extracted:
            return
        self.tags.set(extracted)
```

- `Sequence(lambda n: ...)` — 호출할 때마다 n이 증가하여 고유한 값 생성 (unique 제약 회피)
- `django_get_or_create` — 같은 값이 있으면 생성 대신 기존 객체 반환 (TagFactory에서 slug 중복 방지)
- `@post_generation` — 객체 생성 후 M2M 관계를 설정. `LearningLogFactory(tags=[tag1, tag2])`로 전달할 때만 동작

---

## GitHub Actions CI 환경

로컬에서는 Docker Compose로 web + db 컨테이너를 띄워서 개발하지만, GitHub Actions에서는 Docker 이미지를 빌드하지 않는다.

```yaml
# GitHub Actions workflow
steps:
  - uses: actions/setup-python@v5     # 러너 VM에 Python 직접 설치
    with:
      python-version: '3.11'
  - run: pip install -r requirements.txt  # pip으로 직접 설치
  - run: pytest                           # VM에서 직접 실행
```

| 환경 | 방식 |
| --- | --- |
| 로컬 개발 | Docker Compose (web + db 컨테이너) |
| GitHub Actions | ubuntu 러너 VM에 Python 직접 설치 + DB만 services 컨테이너 |

GitHub Actions의 `ubuntu-latest` 러너는 가상머신이다. Docker 이미지를 매번 빌드하면 CI가 느려지므로, Python과 패키지를 VM에 직접 설치하고 DB만 `services`로 PostgreSQL 컨테이너를 띄운다.

### Docker ↔ GitHub Actions DB 접속 차이

로컬 Docker에서는 DB 호스트가 `db` (docker-compose 서비스명)이지만, GitHub Actions에서는 `localhost`다

```python
# settings.py
'HOST': os.getenv('DATABASE_HOST', 'db'),
```

| 환경 | DATABASE_HOST | 결과 |
| --- | --- | --- |
| 로컬 Docker | 미설정 → 기본값 `'db'` | docker-compose의 db 서비스에 연결 |
| GitHub Actions | `localhost` (workflow에서 설정) | services로 띄운 PostgreSQL에 연결 |

---

## pytest 디버깅 환경 구성

기존에 Django 서버 디버깅용으로 debugpy 포트 5678을 사용하고 있었다. pytest 디버깅을 위해 별도 포트 5679를 추가했다.

```yaml
# docker-compose.yml
ports:
  - "8000:8000"
  - "5678:5678"   # Django 서버 디버깅
  - "5679:5679"   # pytest 디버깅
```

```json
// launch.json — pytest 디버깅용 설정 추가
{
    "name": "Pytest: Remote Attach",
    "type": "debugpy",
    "request": "attach",
    "connect": {
        "host": "localhost",
        "port": 5679
    },
    "pathMappings": [
        {
            "localRoot": "${workspaceFolder}",
            "remoteRoot": "/app"
        }
    ],
    "justMyCode": false
}
```

```bash
# 1. 터미널에서 pytest를 debugpy로 실행 (VS Code 연결 대기)
docker compose exec web python -m debugpy --listen 0.0.0.0:5679 --wait-for-client -m pytest -v

# 2. VS Code에서 "Pytest: Remote Attach" 선택 → F5
```

- `-wait-for-client` 옵션으로 VS Code가 연결될 때까지 대기한 후 테스트가 실행된다. 서버 디버깅(5678)과 포트가 분리되어 있으므로 서버를 띄운 채로 pytest 디버깅이 가능하다.

---

## 테스트 작성 중 발견한 것들

### resp.content는 bytes 타입

Django 테스트 클라이언트의 `resp.content`는 `bytes` 타입이다:

```python
resp.content          # b'<html>...'  (bytes)
resp.content.decode()  # '<html>...'  (str)
```

`bytes`와 비교할 때는 `b""` 리터럴을 사용해야 한다:

```python
# b""는 bytes 리터럴이고 f""는 변수 삽입용 f-string이다. resp.content가 bytes이므로 b""로 맞춰주거나, .decode()로 str 변환 후 비교해야 한다

# bytes끼리 비교
assert b"log-card" in resp.content

# str끼리 비교
assert "log-card" in resp.content.decode()
```

### HTML 응답에서 요소 개수를 셀 때 주의

처음에 카드 개수를 이렇게 검증했다

```python
# 의도: 카드가 1개인지 확인
assert resp.content.count(b"log-card") == 1
```

실제로는 2가 나왔다. `log-card`라는 문자열이 카드 html뿐만 아니라 scripts에서도 사용되기 때문이다

```html
<!-- 카드 HTML에서 1번 -->
<div class="log-card card bg-base-100 ...">

<!-- JavaScript에서도 1번 -->
<script>
document.querySelectorAll('.log-card')
</script>
```

단순 문자열 카운트 대신 템플릿 context를 직접 확인하는 것이 정확하다

```python
# 틀린 방법: HTML + JS 모두 카운트됨
assert resp.content.count(b"log-card") == 1

# 올바른 방법: 템플릿에 넘긴 데이터를 직접 확인
assert len(resp.context['logs'].object_list) == 1
```

### refresh_from_db()가 필요한 이유

북마크 PATCH 테스트에서

```python
log = LearningLogFactory(is_bookmarked=False)           # Python 메모리: False
api_client.patch(url, {"is_bookmarked": True}, ...)      # DB는 True로 변경됨
# 이 시점에서 log.is_bookmarked은 여전히 False

log.refresh_from_db()                                    # DB에서 최신 값 다시 읽어옴
assert log.is_bookmarked is True                         
```

`api_client.patch()`는 HTTP 요청으로 DB를 업데이트하지만, Python에서 log 변수는 생성 시점의 값을 그대로 들고 있다. `refresh_from_db()`는 DB에서 최신 데이터를 다시 가져와서 python 객체를 동기화한다.