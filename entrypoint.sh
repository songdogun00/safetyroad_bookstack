#컨테이너 시작 시 Bookstack 환경설정 및 마이그레이션 수행

cd /var/www/bookstack

# autoload.php 없으면 composer install
if [ ! -f vendor/autoload.php ]; then
  composer install --no-interaction --prefer-dist
fi

chown -R www-data:www-data storage bootstrap/cache || true
chmod -R 775 storage bootstrap/cache || true


# ── 폰트 준비 & dompdf 캐시 워밍업 ────────────────────────────
FONT_SRC="/var/www/bookstack/fonts"                    # COPY fonts/ ./fonts 로 들어온 원본
FONT_DEST="/var/www/bookstack/storage/fonts/dompdf"    # BookStack이 실제로 스캔하는 위치 (볼륨 안)

echo "[fonts] copying ttf into storage volume..."
mkdir -p "$FONT_DEST"
cp -n "$FONT_SRC"/*.ttf "$FONT_DEST"/ 2>/dev/null || true

echo "[fonts] fixing permissions..."
chown -R www-data:www-data storage/fonts/dompdf/* || true
chmod -R 775 storage/fonts

# key 없으면 생성
php artisan key:generate --force || true
php artisan migrate --force || true

php artisan config:clear || true
php artisan cache:clear || true

echo "[fonts] warming dompdf font cache via real PdfGenerator..."
su -s /bin/sh www-data -c "cd /var/www/bookstack && HOME=/tmp php artisan tinker --execute='
(new \\BookStack\\Exports\\PdfGenerator())->fromHtml(\"<html><body style=\\\"font-family: Nanum Gothic\\\">cache warmup</body></html>\");
echo \"nanumgothic cache warmed\n\";
'" || echo "[fonts] WARN: warmup failed; will lazily regenerate on first export"
# ─────────────────────────────────────────────────────────────

chown -R www-data:www-data storage/fonts/dompdf/* || true

exec php-fpm
