# Render 무료 배포 + DB 동기화 + 자동 백업 구현

[https://github.com/aengu/learn-log/commit/d6a1348c57026dce02beb64ba8bb66db1470caf8](https://github.com/aengu/learn-log/commit/d6a1348c57026dce02beb64ba8bb66db1470caf8)

| 항목 | 내용 |
| --- | --- |
| 목적 | Django 프로젝트를 무료로 배포하고, 로컬-프로덕션 DB 동기화 및 자동 백업 체계 구축 |
| 플랫폼 | Render (무료 플랜) |
| DB 동기화 | Django management command (dbpush / dbpull) |
| 자동 백업 | GitHub Actions + Artifacts (주 1회) |

---

## 왜 Render인가?

1. **무료 플랜에 PostgreSQL DB 포함** — 별도 DB 호스팅 비용 없음
2. **GitHub 연동 자동 배포** — push만 하면 빌드/배포 자동 실행
3. **Django/Python 네이티브 지원** — 별도 Docker 설정 없이 바로 배포 가능
4. **render.yaml 기반 IaC** — 인프라 설정을 코드로 관리

---

## Render란?

클라우드 호스팅 플랫폼. Heroku 무료 플랜 종료 이후 대안으로 많이 쓰임.
Web Service + Managed PostgreSQL을 제공하며, Free tier는 월 750시간 + DB 90일 수명.

---

## 배포 구조

```
[GitHub push] ──▶ [Render 자동 감지]
                        │
                        ▼
                  [build.sh 실행]
                  ├── pip install -r requirements.txt
                  ├── python manage.py collectstatic --no-input
                  └── python manage.py migrate
                        │
                        ▼
                  [gunicorn config.wsgi:application]
                        │
                        ▼
                  [서비스 시작 완료]
```

---

## 1. 배포 설정 (render.yaml)

```yaml
# render.yaml
databases:
  - name: learnlog-db
    plan: free
    databaseName: learnlog
    user: learnlog_user

services:
  - type: web
    name: learn-log
    runtime: python
    plan: free
    buildCommand: ./build.sh
    startCommand: gunicorn config.wsgi:application
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: learnlog-db
          property: connectionString
      - key: SECRET_KEY
        generateValue: true
      - key: DEBUG
        value: "False"
      - key: PYTHON_VERSION
        value: "3.12.4"
```

**핵심 포인트:**

- `databases`: Render Managed PostgreSQL 자동 생성
- `fromDatabase`: DB 연결 문자열을 환경변수로 자동 주입
- `generateValue`: SECRET_KEY를 Render가 자동 생성

---

## 2. DB 설정 분기 (config/settings.py)

```python
DATABASE_URL = os.getenv('DATABASE_URL')
if DATABASE_URL:
    # Render 프로덕션: DATABASE_URL 환경변수로 연결
    DATABASES = {
        'default': dj_database_url.parse(DATABASE_URL)
    }
else:
    # 로컬 Docker: 직접 설정
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': 'learnlog',
            'USER': 'learnlog_user',
            'PASSWORD': 'learnlog_password',
            'HOST': os.getenv('DATABASE_HOST', 'db'),
            'PORT': '5432',
        }
    }
```

- Render에서는 `DATABASE_URL`이 자동 주입되므로 `dj_database_url`로 파싱
- 로컬에서는 `DATABASE_URL`이 없으므로 Docker 컨테이너(`db`) 직접 연결
- `dj_database_url`: URL 문자열을 Django DATABASES 딕셔너리로 변환해주는 라이브러리

---

## 3. DB 동기화 — dbpush / dbpull

### 왜 필요한가?

Render는 컨테이너 안에 DB가 포함된 게 아니라, **독립된 Managed DB**를 사용한다.
→ 로컬 Docker DB와 Render DB는 완전히 별개이므로 수동 동기화가 필요.

- "로컬 Django에서 Render DB에 직접 연결하면 안 되나?"
→ 가능하지만 비효율적
    - 네트워크 레이턴시 (모든 쿼리가 외부 DB로)
    - 개발 중 실수로 프로덕션 데이터 오염 위험
    - 오프라인 개발 불가

### 동기화 흐름

```
dbpush (로컬 → Render):
[로컬 Docker DB] ──pg_dump──▶ [임시 .dump 파일] ──pg_restore──▶ [Render DB]

dbpull (Render → 로컬):
[Render DB] ──pg_dump──▶ [임시 .dump 파일] ──pg_restore──▶ [로컬 Docker DB]
```

### dbpush 코드

```python
# search/management/commands/dbpush.py
class Command(BaseCommand):
    help = "로컬 Docker DB를 Render 프로덕션 DB로 밀어넣습니다"

    def handle(self, *args, **options):
        remote_url = os.getenv("REMOTE_DATABASE_URL")

        local = self._parse_local_db()

        with tempfile.NamedTemporaryFile(suffix=".dump", delete=False) as f:
            dump_path = f.name

        try:
            self._dump_local(local, dump_path)
            self._restore_remote(remote_url, dump_path)
        finally:
            if os.path.exists(dump_path):
                os.unlink(dump_path)

    def _dump_local(self, local, dump_path):
        """로컬 Docker DB를 pg_dump로 덤프"""
        env = os.environ.copy()
        env["PGPASSWORD"] = local["password"]
        result = subprocess.run(
            [
                "pg_dump",
                "--no-owner",
                "--no-privileges",
                "--format=custom",
                f"--file={dump_path}",
                f"--host={local['host']}",
                f"--port={local['port']}",
                f"--username={local['user']}",
                local["name"],
            ],
            capture_output=True,
            text=True,
            env=env,
        )

    def _restore_remote(self, url, dump_path):
        """Render DB에 복원"""
        result = subprocess.run(
            [
                "pg_restore",
                "--clean",
                "--if-exists",
                "--no-owner",
                "--no-privileges",
                f"--dbname={url}",
                dump_path,
            ],
            capture_output=True,
            text=True,
        )
```

- **`subprocess.run()`**: 파이썬에서 외부 시스템 명령어(`pg_dump`, `pg_restore`)를 실행하는 함수. 리스트로 명령어와 인자를 전달하고, `capture_output=True`로 출력을 캡처함.
- **`tempfile.NamedTemporaryFile(suffix=".dump")`**: 시스템 임시 디렉토리(`/tmp` 등)에 `.dump` 파일 생성. `delete=False`로 자동 삭제를 막고, 작업 완료 후 `os.unlink()`로 수동 삭제.
- **`pg_dump --format=custom`**: PostgreSQL 커스텀 포맷으로 덤프 (압축 + 선택적 복원 지원)
- **`pg_restore --clean --if-exists`**: 복원 전 기존 테이블 삭제 후 새로 생성
- **`-no-owner`, `-no-privileges`**: 소유자/권한 정보 제외 (로컬↔Render 유저가 다르므로)
- **`PGPASSWORD` 환경변수**: `pg_dump`에 비밀번호 전달 (로컬 DB용). Render DB는 URL에 인증정보가 포함되어 있으므로 별도 불필요
- dbpull도 방향만 반대일 뿐 동일한 구조.

### 사용법

```bash
docker compose exec web python manage.py dbpush   # 로컬 → Render
docker compose exec web python manage.py dbpull   # Render → 로컬
```

```bash
❯ docker compose exec web python manage.py dbpush
⚠ Render 프로덕션 DB의 모든 데이터가 로컬 데이터로 교체됩니다!
  이 작업은 되돌릴 수 없습니다.
정말 계속하시겠습니까? (yes를 입력): yes
로컬 DB 덤프 중...
  덤프 완료
Render DB 복원 중...
  복원 완료
✓ dbpush 완료! 로컬 → Render 동기화 성공
```

---

## 4. 자동 백업 (GitHub Actions)

### 왜 필요한가?

Render Free 플랜의 **DB 수명은 90일**. 만료되면 데이터가 삭제된다.
→ 주기적으로 백업해서 만료 시 복원할 수 있도록 함.

```yaml
# .github/workflows/backup.yml
name: DB Backup

on:
  schedule:
    # 매주 일요일 15:00 UTC (KST 월요일 00:00)
    - cron: '0 15 * * 0'
  workflow_dispatch:  # 수동 실행 가능

jobs:
  backup:
    runs-on: ubuntu-latest

    steps:
      - name: Install PostgreSQL client
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      - name: Dump database
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: |
          pg_dump --no-owner --no-privileges --format=custom \\
            --file=learnlog_backup.dump "$DATABASE_URL"

      - name: Upload backup artifact
        uses: actions/upload-artifact@v4
        with:
          name: db-backup-${{ github.run_id }}
          path: learnlog_backup.dump
          retention-days: 90
```

**핵심 포인트:**

- `schedule` + `workflow_dispatch`: 주 1회 자동 실행 + 수동 실행 가능
- **GitHub Artifacts**: 빌드 산출물 저장소. 파일을 GitHub에 보관할 수 있음
- `retention-days: 90`: 아티팩트 보관 기간 90일, 이후 자동 삭제

### 트러블 슈팅: db 백업 실패

${{ secrets.DATABASE_URL }} 등록을 안 해서 로컬 경로  .s.PGSQL.에 로컬소켓연결 실패함 → 깃헙 settings에서 render external database url로 등록해주면 된다.

```html
# git workflow 에러메세지
pg_dump --no-owner --no-privileges --format=custom \
    --file=learnlog_backup.dump "$DATABASE_URL"
  shell: /usr/bin/bash -e {0}
  env:
    DATABASE_URL: 
pg_dump: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
Error: Process completed with exit code 1.
```

![[attachments/Render 무료 배포 + DB 동기화 + 자동 백업 구현 - image.png]]

GitHub Secrets: 비밀번호/API 키 같은 민감한 정보를 안전하게 저장하는 곳

Secrets 등록 후에도 실패했다. GitHub Actions 러너의 PostgreSQL 클라이언트 버전(16)과 Render DB 서버 버전(18)이 맞지 않아서 `pg_dump`가 실행을 거부하는 문제였다.

```html
# git workflow 에러메세지
pg_dump --no-owner --no-privileges --format=custom
--file=learnlog_backup.dump "$DATABASE_URL"
shell: /usr/bin/bash -e {0}
env:
DATABASE_URL: ***
pg_dump: error: aborting because of server version mismatch
pg_dump: detail: server version: 18.1 (Debian 18.1-1.pgdg12+2); pg_dump version: 16.13 (Ubuntu 16.13-1.pgdg24.04+1)
```

render는 자동으로 최신 버전을 사용하고(18버전), 워크플로우는 기본 버전(16)을 사용해서 그렇다. 워크플로우의 postgresql client버전을 명시적으로 18로 맞춰주면 된다.

```yaml
# backup.yml
- name: Install PostgreSQL client
        run: |
          sudo apt-get update
          sudo apt-get install -y gnupg
          echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
          wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
          sudo apt-get update
          sudo apt-get install -y postgresql-client-18

      - name: Dump database
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: |
          /usr/lib/postgresql/18/bin/pg_dump --no-owner --no-privileges --format=custom \
            --file=learnlog_backup.dump "$DATABASE_URL"
```

**성공! 아래 아티팩트에서 dump파일을 다운받을 수 있다.**

![[attachments/Render 무료 배포 + DB 동기화 + 자동 백업 구현 - image 1.png]]

### 백업 아티팩트가 쌓이는 문제

아티팩트 이름에 `github.run_id`(매 실행마다 고유)가 포함되므로, 실행할 때마다 별도의 아티팩트가 생성된다:

```
db-backup-12345   (1/5 생성)  ← 90일 후 자동 삭제
db-backup-12346   (1/12 생성) ← 90일 후 자동 삭제
db-backup-12347   (1/19 생성) ← 90일 후 자동 삭제
...
```

- 자동 실행만 했을 때: **주 1회 × 90일 보관 = 최대 ~13개 공존**
- 수동 실행을 자주 하면 그만큼 더 쌓임
- 90일 지난 건 GitHub이 자동 삭제하므로 무한히 쌓이지는 않음
- 단, **GitHub Free 기준 아티팩트 저장소 한도는 500MB** — DB가 커지면 주의 필요

---

## 파일 구조

```
├── render.yaml                              # Render IaC 설정
├── build.sh                                 # render용 빌드 스크립트
├── config/
│   └── settings.py                          # DB 분기, Render 호스트 설정
├── docker-compose.yml                       # 로컬 개발환경 (REMOTE_DATABASE_URL 전달)
├── search/
│   └── management/
│       └── commands/
│           ├── dbpush.py                    # 로컬 → Render 동기화
│           └── dbpull.py                    # Render → 로컬 동기화
└── .github/
    └── workflows/
        └── backup.yml                       # 주간 자동 백업
```

---

## 개선할 점

- Render 무료 플랜은 15분간 요청이 없으면 컨테이너가 슬립되어 재활성에 약 30초 소요. 10분마다 자동 GET 요청을 보내는 keep-alive 스레드로 해결. → 개선완료 [[render 배포웹 슬립 방지]]