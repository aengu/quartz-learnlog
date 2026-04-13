# render 배포웹 슬립 방지

## Render 컨테이너 keep-alive 스레드 추가

[https://github.com/aengu/learn-log/commit/029b06233e776b13eac6e2d26bea0f803b8deb5b](https://github.com/aengu/learn-log/commit/029b06233e776b13eac6e2d26bea0f803b8deb5b)

| 항목 | 내용 |
| --- | --- |
| 목적 | Render 무료 플랜의 15분 비활성 슬립을 방지하여 콜드스타트(~30초) 제거 |
| 구현 위치 | `search/apps.py` — Django `AppConfig.ready()` |
| 방식 | 데몬 스레드에서 10분마다 자기 자신에게 GET 요청 |
| 환경변수 | `RENDER_EXTERNAL_URL` (Render 대시보드에서 설정) |

### 문제

Render Free 플랜은 **15분간 요청이 없으면 컨테이너를 슬립** 시킨다. 슬립 상태에서 다시 요청이 들어오면 컨테이너를 재시작하는데, 이 **콜드스타트에 약 30초**가 걸린다. 포트폴리오 사이트 특성상 방문 빈도가 낮아 거의 항상 슬립 상태.

### 고려한 방법들

| 방식 | 문제점 |
| --- | --- |
| **cron** | Render Free 플랜은 컨테이너 내부 cron을 지원하지 않음. Background Worker는 별도 유료 서비스 |
| **Celery** | Redis/RabbitMQ 같은 메시지 브로커가 필요 → 무료 플랜에서 추가 인프라 불가. 단순 ping 하나에 Celery는 과도함 |
| **UptimeRobot 등 외부 서비스** | 가장 일반적인 방법이지만, 외부 서비스 의존성을 더 늘리고 싶지 않았음. 계정 관리 포인트가 늘어남 |
| **render의 health check 기능** | render에서 트래픽으로 안 쳐줌 |

→ **Django 프로세스 안에서 데몬 스레드를 돌리는 것**이 가장 심플하고 추가 비용/의존성 없는 방법.

### 구현

```
[gunicorn 시작]
      │
      ▼
[Django ready() 호출]
      │
      ├── RENDER_EXTERNAL_URL 환경변수 확인
      │         │
      │    (없으면 종료 — 로컬 개발 환경)
      │         │
      │    (있으면)
      │         ▼
      └── 데몬 스레드 시작
                │
                ▼
          ┌─── loop ───┐
          │ sleep(600) │  ← 10분 대기
          │ GET 요청    │  ← 자기 자신에게 ping
          └────────────┘
```

### 코드

```python
# search/apps.py
from django.apps import AppConfig
import os
import threading
import urllib.request

class SearchConfig(AppConfig):
    name = 'search'

    def ready(self):
        """render 환경이면 keep alive 데몬 실행"""
        render_url = os.environ.get('RENDER_EXTERNAL_URL')
        if not render_url:
            return

        def keep_alive():
            import time
            while True:
                time.sleep(600)  # 10분
                try:
                    urllib.request.urlopen(render_url)
                except Exception:
                    pass

        thread = threading.Thread(target=keep_alive, daemon=True)
        thread.start()
```

### 핵심 포인트

- **`AppConfig.ready()`**: Django 앱이 로드될 때 한 번 호출되는 훅. 모든 모델/시그널 등록이 완료된 시점에 실행됨
- **`daemon=True`**: 데몬 스레드로 설정. 메인 프로세스(gunicorn)가 종료되면 이 스레드도 자동 종료됨. `daemon=False`면 스레드가 살아있는 한 프로세스가 종료되지 않아 배포 시 문제 발생
- **`RENDER_EXTERNAL_URL` 분기**: 로컬 개발 환경에서는 이 환경변수가 없으므로 스레드가 시작되지 않음. Render에서만 동작
- **`urllib.request.urlopen`**: 표준 라이브러리만 사용. `requests` 같은 외부 패키지 의존성 없이 HTTP GET 요청 가능
- **`except Exception: pass`**: 네트워크 오류가 발생해도 무시하고 다음 루프 계속. keep-alive는 best-effort이므로 실패해도 문제없음

### 환경변수 설정 (Render 대시보드)

```
RENDER_EXTERNAL_URL = https://learn-log.onrender.com/
```

설정 후 슬립 없이 정상 동작하는 것을 확인했다.

![[attachments/render 배포웹 슬립 방지 - image.png]]

### 한계

- Render가 정책을 변경하여 self-ping을 차단하면 동작하지 않음
- 무료 플랜 월 750시간 제한 — keep-alive로 24시간 가동 시 **월 ~720시간** 소모. 한 서비스만 운영한다면 한도 내