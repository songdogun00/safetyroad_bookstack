## 사용자 중심으로 설치가이드 작성할 것

-------------------------------------------------------------------------------------------------
# BookStack (standalone, 형상 관리)

BookStack + 전용 MariaDB 를 Docker Compose 로 단독 구동하기 위한 정의입니다.
BookStack 은 MySQL/MariaDB 전용이라 MariaDB 컨테이너를 함께 띄웁니다.
데이터 볼륨은 프로젝트 폴더 내부가 아니라 **호스트의 외부 절대 경로(`${DATA_ROOT}`)** 에 둡니다.

## 구성

| 파일 | 역할 |
|------|------|
| `docker-compose.yml` | BookStack + MariaDB 서비스 정의 (호스트 8000 → 컨테이너 80) |
| `.env.example` | 환경변수 템플릿 (복사해서 `.env` 작성, `DATA_ROOT` 포함) |
| `.gitignore` | `.env` 제외 |
| `Dockerfile` *(선택)* | 초기화 스크립트 주입 등 커스터마이징이 필요할 때만 |
| `custom-init/01-custom-init.sh` *(선택)* | 기동 시 root 로 실행되는 초기화 스크립트 |
사용자 중심으로 설치가이드 

## 최초 실행

```bash
# 1) 환경파일 준비
cp .env.example .env
#    → .env 에서 DATA_ROOT, APP_URL, DB 비밀번호 등을 채웁니다.

# 2) 데이터 디렉터리 미리 생성 + 권한 부여 (Oracle 예시의 mkdir + chown 에 대응)
#    .env 의 DATA_ROOT / PUID / PGID 값에 맞춰 실행하세요. 예: DATA_ROOT=/opt/bookstack
sudo mkdir -p /opt/bookstack/config /opt/bookstack/db
sudo chown -R 1000:1000 /opt/bookstack      # ← PUID:PGID 와 일치시킬 것

# 3) APP_KEY 생성 후 .env 의 APP_KEY 에 기입
docker run -it --rm --entrypoint /bin/bash lscr.io/linuxserver/bookstack:latest appkey

# 4) 기동
docker compose up -d
```

기동 후 `http://<호스트>:8000` 접속.
초기 계정: `admin@admin.com` / `password` — **로그인 즉시 변경하세요.**

## 메모

- **데이터 위치**: 실제 데이터는 `${DATA_ROOT}/config`(BookStack), `${DATA_ROOT}/db`(MariaDB) 에
  저장됩니다. 컨테이너를 지웠다 다시 만들어도 이 경로의 데이터는 보존됩니다.
- **이미지 태그 고정**: `latest` 가 아닌 특정 버전으로 핀했습니다. 재현성을 위해 실행 전
  현재 최신 태그로만 교체하세요.
- **PUID/PGID**: 2)번의 `chown` 대상 uid/gid 와 `.env` 의 PUID/PGID 를 반드시 일치시키세요.
- **APP_URL 변경 시** (데이터가 이미 있는 상태):
  ```bash
  docker exec -it bookstack php /app/www/artisan bookstack:update-url <이전URL> <새URL>
  ```

## 백업

```bash
docker compose exec bookstack_db sh -c 'mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" bookstackapp > /dumps/backup.sql'
```

## 업데이트

태그를 새 버전으로 바꾼 뒤:

```bash
docker compose pull
docker compose up -d
```

마이그레이션은 기동 시 자동 수행됩니다. 메이저 업데이트 전엔 릴리스 노트를 확인하세요.
