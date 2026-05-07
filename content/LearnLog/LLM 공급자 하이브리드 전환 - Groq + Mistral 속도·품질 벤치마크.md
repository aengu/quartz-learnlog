# LLM 공급자 하이브리드 전환 - Groq + Mistral 속도·품질 벤치마크

| 항목 | 내용 |
| --- | --- |
| 목적 | 답변 품질을 높이기 위해 LLM 공급자를 변경하되, 속도 저하를 최소화하는 조합 찾기 |
| 방식 | Mistral Large / Mistral Small / Groq Llama 3.3을 작업별로 벤치마크 후 하이브리드 채택 |
| 범위 | `search/services.py` — `generate_answer`, `extract_tags`, `convert_to_markdown` |

---

## 1. 발단 — Groq에서 Mistral로 변경한 이유

기존에는 답변 생성, 태그 추출, 마크다운 변환 세 작업 모두 **Groq (Llama 3.3 70B)**를 사용하고 있었다. 무료 플랜이고 속도도 빨라서 개발 초기에는 문제가 없었는데, 답변 품질이 아쉬웠다. 설명이 피상적이거나, 코드 예시가 부정확한 경우가 종종 있었다.

Mistral Large 3를 붙여보니 답변 퀄리티가 체감될 정도로 좋아졌다. 개념 설명의 깊이, 코드 예시의 정확도, 한국어 표현의 자연스러움 모두 한 단계 올라갔다.

Mistral 공식 발표 기준으로 모델별 포지셔닝은 다음과 같다:

| 모델 | 비교 대상 |
|---|---|
| **Mistral Large 3** | GPT-4o, Claude 3.5 Sonnet급 — LMArena 오픈소스 비추론 모델 중 #2 |
| **Mistral Medium 3** | Claude 3.7 Sonnet의 90% 수준 |
| **Mistral Small 3** | Llama 3.3 70B급 |

기존에 쓰던 Groq의 Llama 3.3 70B가 Mistral Small급이니, Large로 올리면 GPT-4o/Claude 3.5 Sonnet 티어로 올라가는 셈이다. 실제로 같은 질문에 대해 Large와 Small의 답변을 비교해봤을 때, Large가 답변 구조의 체계성과 설명의 깊이에서 확실히 우위였다.

> 출처: [Mistral Large 3 공식 발표](https://mistral.ai/news/mistral-large), [Mistral Medium 3 발표](https://mistral.ai/news/mistral-medium-3), [Mistral Small 3.1 발표](https://mistral.ai/news/mistral-small-3-1)

그래서 세 작업 전부를 Mistral Large로 교체했다.

---

## 2. 문제 — 너무 느리다

Mistral로 바꾸고 나니 체감 속도가 크게 떨어졌다. Groq에서는 질문 하나에 6~7초면 끝나던 게, Mistral에서는 1분 이상 걸렸다. 답변 품질은 좋아졌지만 사용성이 나빠진 것이다.

속도 차이를 수치로 확인하기 위해 벤치마크를 진행했다.

---

## 3. 첫 번째 벤치마크 — Mistral Large vs Small

같은 프롬프트로 Mistral의 두 모델을 비교했다. 테스트 질문은 "Docker 컨테이너와 가상머신의 차이점"으로 실제 서비스에서 들어올 법한 기술 질문을 사용했다.

```python
# benchmark_mistral.py
MODELS = ["mistral-large-latest", "mistral-small-latest"]
TASKS = {
    "답변 생성 (heavy)":    {"max_tokens": 2000, "temperature": 0.7},
    "태그 추출 (light)":     {"max_tokens": 50,   "temperature": 0.2},
    "마크다운 변환 (medium)": {"max_tokens": 1000, "temperature": 0.5},
}
```

### 결과

| 작업 | large | small | 속도 차이 |
|---|---|---|---|
| 답변 생성 | 35.81s | 13.53s | 2.6x |
| 태그 추출 | 0.92s | 0.62s | 1.5x |
| 마크다운 변환 | 18.73s | 6.36s | 2.9x |
| **전체 합계** | **55.46s** | **20.50s** | **2.7x** |

Small이 2.7배 빠르지만, 답변만 Large를 쓰고 나머지를 Small로 바꾸는 하이브리드 예상치는 **42.78s** — 전부 Large 대비 23% 절감. 병목이 답변 생성(전체의 65%)에 있어서 나머지를 아무리 줄여도 효과가 크지 않았다.

---

## 4. 두 번째 벤치마크 — Groq 하이브리드

Mistral Small 대신 기존에 쓰던 Groq을 다시 붙여보면 어떨까? 어차피 태그 추출이나 마크다운 변환은 품질보다 속도가 중요한 작업이다.

세 가지 조합을 비교했다.

```python
# benchmark_hybrid.py
CONFIGS = {
    "A) 전부 Mistral Large":                    답변=Mistral, 태그=Mistral, 마크다운=Mistral,
    "B) 전부 Groq Llama3.3":                     답변=Groq,    태그=Groq,    마크다운=Groq,
    "C) 하이브리드 (답변=Mistral, 나머지=Groq)":    답변=Mistral, 태그=Groq,    마크다운=Groq,
}
```

### 결과

| 조합 | 답변 생성 | 태그 추출 | 마크다운 변환 | **합계** |
|---|---|---|---|---|
| A) 전부 Mistral Large | 47.63s | 0.86s | 19.37s | **67.85s** |
| B) 전부 Groq | 4.32s | 0.58s | 1.84s | **6.74s** |
| C) 하이브리드 | 44.87s | 0.63s | 2.44s | **47.93s** |

| 비교 | 결과 |
|---|---|
| 하이브리드 vs 전부 Large | **29% 절감** |
| 하이브리드 vs 전부 Groq | +611% (품질 향상 대가) |

Groq의 tok/s가 압도적이다. Mistral Large가 ~43 tok/s인 반면 Groq은 ~180 tok/s로 4배 이상 빠르다. 태그 추출(0.63s)과 마크다운 변환(2.44s)이 사실상 무시 가능한 수준이 됐다.

---

## 5. max_tokens을 줄이면 답변 생성도 빨라질까?

병목인 답변 생성(Mistral Large)의 max_tokens을 줄여서 속도를 개선할 수 있는지도 테스트했다.

| max_tokens | 실제 생성 | 소요시간 | 상태 |
|---|---|---|---|
| 500 | 500 tok | 11.25s | 잘림 |
| 1000 | 1000 tok | 22.42s | 잘림 |
| 1500 | 1500 tok | 33.49s | 잘림 |
| **2000** | **1653 tok** | **40.84s** | **자연 종료** |
| 3000 | 1431 tok | 33.18s | 자연 종료 |

1500까지는 토큰이 꽉 차서 답변이 중간에 잘렸다. 자연 종료 기준이 대략 1400~1650 토큰이므로, max_tokens을 줄여도 실제 생성량은 변하지 않는다. tok/s가 일정(~44)하기 때문에 **속도는 실제 생성 토큰 수에 비례**하고, max_tokens 상한을 줄이는 것만으로는 의미가 없다.

답변을 짧게 만들려면 프롬프트에서 "간결하게 작성"을 지시하는 쪽이 맞다. 이번에는 적용하지 않았다.

---

## 6. 최종 구성

| 작업 | 공급자 | 모델 | 이유 |
|---|---|---|---|
| 답변 생성 | Mistral | mistral-large-latest | 품질이 확실히 좋다 |
| 태그 추출 | Groq | llama-3.3-70b-versatile | 단순 작업, 속도 우선 |
| 마크다운 변환 | Groq | llama-3.3-70b-versatile | 포맷 변환, 속도 우선 |
| 웹 검색 | Tavily | - | 기존 유지 |

```python
# search/services.py
class LearnlogService:
    def __init__(self):
        self.mistral_client = Mistral(
            api_key=settings.MISTRAL_API_KEY,
            timeout_ms=120_000,  # Mistral Large가 40~50초 걸리므로 넉넉하게
        )
        self.groq_client = Groq(api_key=settings.GROQ_API_KEY)
        self.tavily_client = TavilyClient(api_key=settings.TAVILY_API_KEY)
```

### 예상 소요시간

| 구성 | 소요시간 |
|---|---|
| 변경 전 (전부 Groq) | ~7s |
| 변경 후 (하이브리드) | ~48s |
| 만약 전부 Mistral이었다면 | ~68s |

답변 품질은 Mistral Large 수준을 유지하면서, 전부 Mistral을 쓸 때보다 29% 빠르다. 대신 Groq만 쓸 때보다는 확실히 느려졌다 — 이건 답변 품질을 위한 트레이드오프로 받아들였다.

---

## 7. 트러블 슈팅— mistralai 패키지 import 오류

Mistral로 전환하면서 `mistralai` 패키지를 설치했는데, import가 안 되는 문제가 있었다.

```python
from mistralai import Mistral
# ImportError: cannot import name 'Mistral' from 'mistralai' (unknown location)
```

`pip show mistralai`로 확인하면 2.4.1이 설치되어 있는데, `mistralai.__file__`이 `None`이고 `__path__`가 `_NamespacePath`였다. 패키지가 namespace package로 쪼개져 있어서 최상위 `__init__.py`가 없는 상태였다.

실제 `Mistral` 클래스는 `mistralai.client` 하위 모듈에 있었다.

```python
# 안 됨
from mistralai import Mistral

# 됨
from mistralai.client import Mistral
```

또 하나, Mistral Large의 응답 시간이 40~50초라서 기본 httpx 타임아웃에 걸리는 문제가 있었다. `timeout_ms=120_000`을 설정해서 해결.

---

## 8. 리팩토링 — services.py 정리

하이브리드 전환 과정에서 모델이 3개로 늘어나면서 코드 정리도 함께 진행했다.

### 모델명 상수화

모델명이 메서드마다 하드코딩되어 있어서, 모델을 바꿀 때마다 여러 곳을 수정해야 했다. 클래스 상수로 빼서 한 곳에서 관리하도록 변경.

```python
class LearnlogService:
    ANSWER_MODEL = "mistral-large-latest"   # 답변 생성
    LIGHT_MODEL = "llama-3.3-70b-versatile" # 태그 추출, 마크다운 변환

class ExerciseService:
    MODEL = "mistral-small-latest"          # 연습문제 생성/채점
```

### JSON 파싱 중복 제거

LLM 응답에서 JSON을 추출하는 로직(마크다운 코드블록 제거 → `json.loads`)이 3곳에서 동일하게 반복되고 있었다. `_parse_json_response` 정적 메서드로 추출해서 한 곳에서 관리.

### 파일 분리 (re-export 패턴)

`services.py` 하나에 `LearnlogService`와 `ExerciseService`가 같이 있었는데, 역할이 다르므로 파일을 분리했다.

```
# 변경 전
search/services.py          # LearnlogService + ExerciseService (550줄)

# 변경 후
search/services/
├── __init__.py              # re-export
├── learnlog_service.py      # LearnlogService
└── exercise_service.py      # ExerciseService
```

`__init__.py`에서 re-export하면 외부 코드의 import를 변경하지 않아도 된다:

```python
# search/services/__init__.py
from .learnlog_service import LearnlogService
from .exercise_service import ExerciseService
```

기존에 `from search.services import LearnlogService`로 쓰던 코드가 그대로 동작한다. Django 자체도 이 패턴을 쓰고 있다 — `from django.db.models import Model`에서 `Model`은 실제로 `django/db/models/base.py`에 있지만, `__init__.py`에서 re-export해서 짧은 경로로 접근 가능하게 한 것이다.
