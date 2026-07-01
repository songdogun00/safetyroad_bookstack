# SafetyRoad BookStack

SafetyRoad 문서 관리용 [BookStack](https://www.bookstackapp.com/) 배포 프로젝트입니다.
linuxserver 이미지를 그대로 쓰는 대신, BookStack 소스(`src/`)를 직접 빌드하는 **커스텀 Docker 이미지**를 사용하며
PDF 내보내기 시 한글이 깨지지 않도록 나눔고딕 폰트를 내장하는 등 SafetyRoad 환경에 맞게 조정되어 있습니다.

## 구성

| 파일 | 역할 |
|------|------|
| `Dockerfile` | Node 20에서 프론트엔드 빌드 → PHP 8.3-fpm 위에 BookStack 소스 및 나눔고딕(+이탤릭 생성) 폰트 포함해 이미지 빌드 |
| `docker-compose.yml` | BookStack(PHP-FPM+Nginx) + MariaDB 11.4 서비스 정의 |
| `entrypoint.sh` | 컨테이너 기동 시 composer install, 권한 정리, 폰트 배치, DB 마이그레이션 등 자동 수행 |
| `.env.example` | 환경변수 템플릿 (복사해서 `.env` 작성) |
| `src/` | BookStack 애플리케이션 소스 (커스텀 마이그레이션 포함) |
| `fonts/` | PDF export용 나눔고딕 폰트 및 이탤릭 생성 스크립트 |

## 문서 안내

- **설치/운영 담당자**라면 → [`README_install.md`](./README_install.md)
  환경설정, 빌드/기동, APP_KEY 발급, DB 커스텀 설정, 백업/업데이트 절차를 다룹니다.
- **BookStack을 실제로 이용하는 최종 사용자**라면 → [`README_User.md`](./README_User.md)
  접속 방법, 문서 작성, 검색, PDF 내보내기, 권한/공유, 자주 겪는 문제(FAQ)를 다룹니다.

## 빠른 시작

```bash
cp .env.example .env
# .env에서 APP_URL, APP_KEY, DB_* 값 채우기 (자세한 내용은 README_install.md 참고)

docker compose build
docker compose up -d
```

기동 후 `http://<호스트>:8000` 접속. 기본 계정: `admin@admin.com` / `password` — **로그인 즉시 비밀번호를 변경하세요.**

자세한 절차는 [`README_install.md`](./README_install.md)를 참고하세요.
