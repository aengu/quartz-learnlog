# vscode에서 Docker 컨테이너 디버깅하기

## 목표

- VSCode에서 Docker 컨테이너 내부 Django 코드를 디버깅
- 브라우저/Postman으로 테스트하면서 브레이크포인트로 멈춰서 변수 확인하기

---

## 핵심 개념 이해

### 로컬 디버깅 vs 컨테이너 디버깅

| 구분 | 로컬 디버깅 | 컨테이너 디버깅 |
| --- | --- | --- |
| **실행 위치** | 내 컴퓨터 | Docker 컨테이너 |
| **필요한 것** | Python, DB 등 전부 설치 | Docker만 |
| **장점** | 익숙함 | 환경 통일, 팀 협업 쉬움 |
| **실무 비율** | 20-30% | 70-80% |

### 볼륨 마운트?

```yaml
volumes:
  - .:/app  # 로컬 폴더 ←→ 컨테이너 폴더 실시간 동기화!

```

- 로컬에서 코드 수정 → 컨테이너에 즉시 반영 ✅
- 컨테이너에서 수정 → 로컬에 즉시 반영 ✅
- **재빌드 불필요!**

### 데이터 보존

```yaml
volumes:
  postgres_data:  # 영구 볼륨

```

- `docker compose down` → 컨테이너 삭제, **데이터 보존** ✅
- `docker compose down -v` → 볼륨까지 삭제, **데이터 삭제** ❌

---

## 시행착오 1: F5 누르면 포트 충돌

### 문제

```
docker compose up -d (포트 8000 사용 중)
→ VSCode에서 F5 (새 서버 시작 시도)
→ "Address already in use" 에러!

```

### 깨달음

- **F5 = 새 프로세스 시작** (launch)
- 이미 실행 중인 서버가 있으면 충돌!

### 해결

- **Attach 방식 사용**: 실행 중인 서버에 디버거만 연결

---

## 시행착오 2: 브레이크포인트가 안 걸림

### 문제

```
브레이크포인트 설정 → F5 → 실행
→ 브레이크포인트에서 안 멈춤 😭

```

### 원인

1. **debugpy가 서버에 안 붙음**
2. Python 확장이 컨테이너 내부에 설치 안 됨
3. Django shell에서는 디버거 연결 안 됨

### 해결

- `debugpy`로 Django 서버 실행
- VSCode Remote Container로 attach
- F5로 디버거 연결

---

## 시행착오 3: Shell에서 상대 import 에러

### 문제

```python
>>> from .services import LearnlogService
KeyError: "'__name__' not in globals"

```

### 해결

```python
# ❌ Shell에서 안 됨
from .services import LearnlogService

# ✅ 절대 경로 사용
from search.services import LearnlogService

```

---

## 최종 해결 방법

### 1. requirements.txt

```
Django>=5.0,<6.0
djangorestframework>=3.14.0
psycopg2-binary>=2.9.9
python-dotenv>=1.0.0
groq>=0.4.0
tavily-python>=0.3.0
debugpy>=1.8.0  # 디버깅용

```

### 2. docker-compose.yml

```yaml
version: '3.8'

name: learnlog

services:
  db:
    image: postgres:15-alpine
    container_name: learnlog_db
    environment:
      POSTGRES_DB: learnlog
      POSTGRES_USER: learnlog_user
      POSTGRES_PASSWORD: learnlog_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: .
    container_name: learnlog_web
    command: >
      sh -c "
        python manage.py migrate &&
        python -Xfrozen_modules=off -m debugpy --listen 0.0.0.0:5678 --wait-for-client manage.py runserver 0.0.0.0:8000 --noreload --nothreading
      "
    volumes:
      - .:/app
    ports:
      - "8000:8000"
      - "5678:5678"  # 디버깅 포트
    depends_on:
      - db
    environment:
      - DEBUG=True
      - GROQ_API_KEY=${GROQ_API_KEY}
      - TAVILY_API_KEY=${TAVILY_API_KEY}

volumes:
  postgres_data:

```

### 3. .vscode/launch.json (컨테이너 내부)

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Remote Attach",
            "type": "debugpy",
            "request": "attach",
            "connect": {
                "host": "localhost",
                "port": 5678
            },
            "pathMappings": [
                {
                    "localRoot": "${workspaceFolder}",
                    "remoteRoot": "/app"
                }
            ],
            "justMyCode": false
        }
    ]
}

```

---

## 디버깅 워크플로우

### 1단계: 서버 시작

```bash
docker compose down
docker compose up -d

# 로그 확인 (대기 중이어야 함)
docker compose logs web
# "Waiting for debugger client to attach..."

```

### 2단계: Remote Container 연결

```
VSCode:
Cmd+Shift+P → "Dev Containers: Attach to Running Container"
→ "learnlog_web" 선택
→ File > Open Folder > /app

```

### 3단계: Python 확장 설치

```
Extensions → "Python" 검색
→ "Install in Container" 클릭

```

### 4단계: launch.json 생성

- `.vscode/launch.json` 파일 생성 (위 내용)

### 5단계: 디버거 연결

```
F5 → "Python: Remote Attach" 선택
→ "Debugger attached!" 메시지 확인
→ 서버 시작됨!

```

### 6단계: 브레이크포인트 설정

```python
# search/views.py
@api_view(['POST'])
def search_view(request):
    query = request.data.get('query')
    # ← 여기 클릭 (빨간 점)

    service = LearnlogService()
    log = service.process_query(query)

    return Response({...})

```

### 7단계: 테스트!

```bash
curl -X POST <http://localhost:8000/api/search/> \\
  -H "Content-Type: application/json" \\
  -d '{"query": "docker network 차이"}'

# 브레이크포인트에서 멈춤! 🎉

```

---

## 유용한 명령어 모음

### Docker 관리

```bash
# 컨테이너 시작
docker compose up -d

# 컨테이너 중지 (데이터 보존)
docker compose down

# 로그 확인
docker compose logs -f web

# 컨테이너 접속
docker compose exec web bash

# Django shell
docker compose exec web python manage.py shell

# 마이그레이션
docker compose exec web python manage.py migrate

```

### 디버깅

```bash
# 서버 재시작
docker compose restart web

# 완전 재시작 (재빌드)
docker compose down
docker compose build --no-cache
docker compose up -d

```

## 배운 것들

### 1. 컨테이너 디버깅이 실무 표준

- 실무의 70-80%가 컨테이너로 개발
- 환경 통일 → "내 컴퓨터에선 되는데?" 방지

### 2. Launch vs Attach

- **Launch**: 새 프로세스 시작 (포트 충돌 가능)
- **Attach**: 실행 중인 프로세스에 연결 (추천!)

### 3. 볼륨 마운트의 힘

- 로컬 코드 수정 → 컨테이너에 즉시 반영
- 재빌드 불필요
- 실시간 개발 가능

### 4. debugpy 동작 원리

```
Django 서버 시작 시 debugpy 포함
→ 포트 5678로 디버거 대기
→ VSCode가 5678로 연결
→ 브레이크포인트 작동!

```

## 참고 자료

- [VSCode Dev Containers 공식 문서](https://code.visualstudio.com/docs/devcontainers/containers)
- [debugpy GitHub](https://github.com/microsoft/debugpy)
- [Docker Compose 공식 문서](https://docs.docker.com/compose/)