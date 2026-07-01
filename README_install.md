# SafetyRoad BookStack 설치 가이드 (사용자용)

이 문서는 실제 코드(`Dockerfile`, `docker-compose.yml`, `entrypoint.sh`, `src/database/migrations`)를 기준으로 작성한
**설치 담당자용** 가이드입니다.

## BookStack (standalone, 형상 관리)

BookStack + 전용 MariaDB 를 Docker Compose 로 단독 구동하기 위한 정의입니다.
BookStack 은 MySQL/MariaDB 전용이라 MariaDB 컨테이너를 함께 띄웁니다.


## 1. 이 구성이 하는 일

- BookStack 소스코드(`src/`)를 PHP 8.3-fpm 이미지 위에 직접 빌드 (`Dockerfile`)
- 프론트엔드(JS/CSS)는 Node 20 스테이지에서 별도 빌드 후 결과물만 복사
- PDF 내보내기(export)에서 한글이 깨지지 않도록 나눔고딕 폰트를 컨테이너에 내장하고,
  이탤릭 서체가 없는 나눔고딕의 특성상 `fonts/make-italic.py`(fontforge)로 이탤릭 폰트를 직접 생성해서 포함
- 최초 기동 시 PDF export에서 나눔고딕이 강제 적용되도록 하는 **DB 설정값을 마이그레이션으로 자동 삽입** (3번 항목 참고)
- Nginx가 정적 파일/업로드 파일을 서빙하고, PHP 요청만 `bookstack` 컨테이너(php-fpm)로 전달
- MariaDB 11.4 컨테이너를 BookStack 전용 DB로 사용

## 2. 사전 준비물

- Docker / Docker Compose (v2, `docker compose` 명령 사용)
- 리눅스 호스트 권장 (uid/gid 권한 처리 때문에 Windows는 비권장)

## 3. 최초 설치 절차

### 3-1. 환경 파일 준비

```bash
cp .env.example .env
```

`.env`에서 아래 값들을 채웁니다.

| 변수 | 설명 |
|------|------|
| `APP_URL` | 접속 주소. `http://<호스트>:8000` 형태, 끝에 슬래시 금지 |
| `APP_KEY` | 아래 명령으로 새로 발급받아 교체  |
| `DB_DATABASE` | BookStack이 사용할 DB 이름 (기본 `bookstackapp`) |
| `DB_USERNAME` / `DB_PASSWORD` | BookStack 전용 DB 계정 |
| `DB_ROOT_PASSWORD` | MariaDB root 비밀번호 |
| `PUID` / `PGID` | 현재는 실제로 사용되지 않음(참고용). 볼륨 권한 문제는 컨테이너 내부에서 `www-data`로 자동 처리됨 |

> 실제 데이터는 프로젝트 폴더 기준 상대경로에 저장됩니다.
> - DB 데이터: `./mariadb`
> - 업로드 파일: `./src/public/uploads`
> - 앱 소스(app/resources/routes/storage/bootstrap): `./src/*` 바인드 마운트
> - 빌드 산출물(public, vendor, dompdf 폰트 캐시): 이름 있는 도커 볼륨(`bookstack_public`, `bookstack_vendor`, `bookstack_dompdf_fonts`)
>
> 필요하면 `docker-compose.yml`을 수정해 외부 절대경로(`DATA_ROOT`)로 바꿀 수 있지만, 현재 코드 그대로는
> 위 상대경로에 데이터가 쌓입니다.

### 3-2. APP_KEY 발급

```bash
docker run -it --rm --entrypoint /bin/bash lscr.io/linuxserver/bookstack:latest appkey
```

출력된 `base64:...` 값을 `.env`의 `APP_KEY`에 붙여넣습니다.

### 3-3. 빌드 & 기동

이 프로젝트는 소스를 직접 빌드하므로(`build: .`) 최초 실행 시 이미지 빌드가 필요합니다.

```bash
docker compose build
docker compose up -d
```

빌드 단계에서 자동으로 일어나는 일:
1. Node 20 컨테이너에서 프론트엔드(JS/SCSS) 빌드
2. fontforge로 나눔고딕 이탤릭/볼드이탤릭 폰트 생성
3. PHP 확장(gd, intl, zip, pdo_mysql 등) 설치 및 BookStack 소스 복사

### 3-4. 최초 기동 시 자동 수행 항목 (`entrypoint.sh`)

컨테이너가 뜰 때마다 아래가 자동으로 실행됩니다.

1. `vendor/autoload.php`가 없으면 `composer install`
2. `storage`, `bootstrap/cache` 권한을 `www-data`로 정리
3. 나눔고딕 ttf를 `storage/fonts/dompdf` 볼륨으로 복사 (dompdf가 실제로 스캔하는 위치)
4. `php artisan key:generate`, **`php artisan migrate --force`**
5. dompdf 폰트 캐시 워밍업 (실제 PDF 생성 1회 실행해서 나눔고딕 캐시를 미리 만들어 둠)

**4번의 마이그레이션 실행 시, 아래 3-5 항목의 DB 설정값도 함께 자동으로 들어갑니다.** 별도 수동 작업이 필요 없습니다.

### 3-5. DB에 들어가는 커스텀 값 (Custom HTML Head Content)

PDF export(dompdf 엔진)에서 나눔고딕 폰트가 강제 적용되도록, BookStack의
"Custom HTML Head Content" 설정(`settings` 테이블의 `app-custom-head` 키)에 아래 CSS가 필요합니다.

```html
<style>
  .export-format-pdf.export-engine-dompdf * {
    font-family: 'nanum gothic', 'DejaVu Sans', sans-serif;
  }
</style>
```

이 값은 **`src/database/migrations/2026_06_30_140000_add_setting_custom_header.php` 마이그레이션에
이미 정의되어 있어, 최초 `php artisan migrate --force` 실행 시 자동으로 `settings` 테이블에 삽입됩니다.**
즉 신규 설치라면 이 문서의 안내대로 `docker compose up -d`만 해도 자동 반영됩니다.

**확인 방법** (Admin 계정으로 로그인 후):
[기본 관리자 계정: `admin@admin.com` / `password`]

`설정(Settings) → 커스터마이징(Customization) → Custom HTML Head Content` 항목에 위 `<style>` 블록이
이미 채워져 있는지 확인합니다.

**자동 반영이 안 되는 경우** (이미 운영 중이던 DB를 그대로 재사용해서, 이 마이그레이션이 추가되기 전에
DB가 만들어졌고 이후 새 마이그레이션이 스킵된 경우 등) 아래 중 하나로 수동 처리하세요.

- Admin UI에서 위 경로로 들어가 `<style>...</style>` 블록을 직접 붙여넣고 저장, 또는
- DB에 직접 삽입:

```sql
INSERT INTO settings (setting_key, value, type, created_at, updated_at)
VALUES (
  'app-custom-head',
  '<style>\n  .export-format-pdf.export-engine-dompdf * {\n    font-family: ''nanum gothic'', ''DejaVu Sans'', sans-serif;\n  }\n</style>',
  'string', NOW(), NOW()
)
ON DUPLICATE KEY UPDATE value = VALUES(value), updated_at = NOW();
```

### 3-6. 접속 확인

- 주소: `http://<호스트>:8000`
- 기본 계정: `admin@admin.com` / `password` — **로그인 즉시 비밀번호를 변경하세요.**

## 4. 백업

```bash
docker compose exec bookstack_db sh -c \
  'mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" bookstackapp' > backup.sql
```

(`./mariadb` 디렉터리를 통째로 복사하는 방식도 가능하지만, 컨테이너를 내린 상태에서 진행하세요.)

## 5. 업데이트

```bash
# src/ 코드나 fonts/ 를 바꾼 뒤
docker compose build
docker compose up -d
```

`entrypoint.sh`가 재기동 시마다 `migrate --force`를 실행하므로 신규 마이그레이션은 자동 반영됩니다.

## 6. 참고: `APP_URL` 을 나중에 바꾸는 경우

```bash
docker exec -it bookstack php artisan bookstack:update-url <이전URL> <새URL>
```
