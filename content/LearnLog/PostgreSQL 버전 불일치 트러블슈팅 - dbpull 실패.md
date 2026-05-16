# PostgreSQL 버전 불일치 트러블슈팅 - dbpull 실패

| 항목 | 내용 |
| --- | --- |
| 상황 | Render DB를 로컬로 가져오는 `dbpull` 커맨드 실패 |
| 원인 | Render DB가 PostgreSQL 18로 올라갔는데, 로컬 환경은 15에 머물러 있었음 |

---

## 에러 1: pg_dump 버전 불일치

```
pg_dump: error: aborting because of server version mismatch
pg_dump: detail: server version: 18.3; pg_dump version: 15.16
```

`dbpull`은 web 컨테이너 안에서 `pg_dump`로 Render DB의 덤프를 뜬다. 그런데 web 컨테이너에 설치된 `pg_dump`(15)가 Render DB(18)보다 낮아서 거부당했다.

### 원인

Dockerfile에서 `postgresql-client`를 설치하면 Debian 기본 저장소의 버전(15)이 깔린다. Debian은 릴리스 시점에 안정적인 버전만 포함시키기 때문에, 이후에 나온 16~18은 기본 저장소에 없다.

### 해결: Dockerfile에서 PostgreSQL 공식 APT 저장소 등록

```dockerfile
# 변경 전
RUN apt-get update && apt-get install -y \
    postgresql-client \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 변경 후
RUN apt-get update && apt-get install -y \
    curl ca-certificates gnupg \
    build-essential \
    libpq-dev \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
       | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] \
       http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
       > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update && apt-get install -y postgresql-client-18 \
    && rm -rf /var/lib/apt/lists/*
```

각 줄의 의미:
- `curl ca-certificates gnupg` — 저장소 등록에 필요한 도구
- `curl ... | gpg --dearmor` — PostgreSQL 공식 저장소의 서명 키 다운로드 및 등록. apt가 패키지를 신뢰할 수 있도록 함
- `echo "deb ..." > pgdg.list` — PostgreSQL 공식 APT 저장소를 소스 목록에 추가. `bookworm`은 이 이미지의 Debian 버전명
- `apt-get update && apt-get install -y postgresql-client-18` — 새 저장소에서 18 버전 클라이언트 설치

> Dockerfile은 **web 컨테이너**만 설정한다. 여기서 설치하는 `postgresql-client`는 DB 서버가 아니라 DB에 접속해서 작업하는 도구 모음 /클라이언트(`pg_dump`, `pg_restore`, `psql` 등)이다!

---

## 에러 2: pg_restore에서 transaction_timeout 미인식

pg_dump는 해결됐지만, 복원 단계에서 또 에러가 났다.

```
pg_restore: error: could not execute query:
ERROR: unrecognized configuration parameter "transaction_timeout"
Command was: SET transaction_timeout = 0;
```

Render DB(18)에서 뜬 덤프 파일에 `transaction_timeout`이라는 PostgreSQL 17+ 전용 설정이 포함돼 있는데, 로컬 DB가 15라서 모르는 설정이었다.

### 해결: docker-compose.yml의 DB 이미지 버전 업그레이드

```yaml
# 변경 전
image: postgres:15-alpine

# 변경 후
image: postgres:18-alpine
```

PostgreSQL은 메이저 버전이 다르면 기존 데이터 파일을 읽을 수 없다. 그래서 기존 볼륨을 삭제하고 새로 올려야 한다.

```bash
docker compose down -v    # -v: 볼륨도 함께 삭제
docker compose up -d
```

어차피 `dbpull`로 Render 데이터를 가져올 거니까 로컬 데이터가 날아가도 문제없다.

> docker-compose의 `postgres:18-alpine`은 **Docker Hub**에서 받는 DB 서버 이미지이고, Dockerfile의 `postgresql-client-18`은 **PostgreSQL APT 저장소**에서 설치하는 CLI 도구다. 같은 PostgreSQL 18이지만 배포 경로가 다르다! 헷갈리지 말자

---

## 에러 3: PostgreSQL 18 데이터 디렉토리 구조 변경

DB 이미지를 18로 올리고 `docker compose up -d`까지 했는데, db 컨테이너가 바로 종료됐다.

```
Counter to that, there appears to be PostgreSQL data in:
  /var/lib/postgresql/data (unused mount/volume)
```

### 원인

PostgreSQL 15까지는 데이터를 `/var/lib/postgresql/data`에 바로 저장했지만, 18부터는 `/var/lib/postgresql/data/18/`처럼 **버전별 하위 폴더**에 저장하는 방식으로 바뀌었다. 나중에 `pg_upgrade`로 버전을 올릴 때 이전 버전과 새 버전의 데이터가 나란히 있어야 편하기 때문이다.

참고: [docker-library/postgres#1259](https://github.com/docker-library/postgres/pull/1259), [docker-library/postgres#37](https://github.com/docker-library/postgres/issues/37)

### 해결: 볼륨 마운트 경로를 한 단계 위로 변경

```yaml
# 변경 전
volumes:
  - postgres_data:/var/lib/postgresql/data

# 변경 후
volumes:
  - postgres_data:/var/lib/postgresql
```

한 단계 위인 `/var/lib/postgresql`에 마운트하면 PostgreSQL이 알아서 하위에 버전별 폴더를 만든다.

```bash
docker compose down -v
docker compose up -d
```

---

## 정리

| 구성 요소 | 변경 전 | 변경 후 | 역할 |
| --- | --- | --- | --- |
| Dockerfile `postgresql-client` | 15 (Debian 기본) | 18 (공식 저장소) | web 컨테이너에서 DB 접속 도구 |
| docker-compose DB 이미지 | `postgres:15-alpine` | `postgres:18-alpine` | 로컬 DB 서버 |
| Render DB | 18 | 18 | 프로덕션 DB 서버 |

세 군데 버전을 모두 맞춰야 `dbpull`(덤프 → 복원) 파이프라인이 정상 동작한다.

dbpull/dbpush 구현과 Render 배포 전체 흐름은 여기서 → [[Render 무료 배포 + DB 동기화 + 자동 백업 구현]]
