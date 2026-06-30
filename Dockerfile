FROM node:20 AS frontend

WORKDIR /app
COPY src/ /app

RUN npm install
RUN npm run build
RUN test -f public/dist/styles.css
#강제로 있는지 테스트

FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install \
        pdo_mysql \
        mbstring \
        bcmath \
        gd \
        intl \
        zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# RUN sed -i 's/listen = .*/listen = 0.0.0.0:9000/' /usr/local/etc/php-fpm.d/www.conf

# WORKDIR /var/www/bookstack/bootstrap
# COPY src/bootstrap/ .

WORKDIR /var/www/bookstack
COPY src/ .

COPY --from=frontend /app/public/dist /var/www/bookstack/public/dist
RUN ls -la /var/www/bookstack/public/dist 
#복사 결과가 로그에 찍힘

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# laravel log 파일 쓰기 권한 부여 

RUN echo "alias ll='ls -alF'" >> /root/.bashrc

CMD ["/entrypoint.sh"]
