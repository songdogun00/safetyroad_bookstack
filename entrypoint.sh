#!/bin/sh

cd /var/www/bookstack

# autoload.php 없으면 composer install
if [ ! -f vendor/autoload.php ]; then
  composer install --no-interaction --prefer-dist
fi

chown -R www-data:www-data storage bootstrap/cache || true
chmod -R 775 storage bootstrap/cache || true

# key 없으면 생성
php artisan key:generate --force || true
php artisan migrate --force || true

php artisan config:clear || true
php artisan cache:clear || true

exec php-fpm
