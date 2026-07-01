FROM node:20 AS frontend

WORKDIR /app
COPY src/ /app

RUN npm install
RUN npm run build

# ── italic 폰트 생성 전용 스테이지 ──────────────────────────
FROM debian:trixie-slim AS fontgen

RUN apt-get update && apt-get install -y --no-install-recommends \
    fontforge python3-fontforge \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /fontwork
COPY fonts/ ./

RUN fontforge -script make-italic.py \
    && ls -la *.ttf
# ─────────────────────────────────────────────────────────────

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

WORKDIR /var/www/bookstack
COPY src/ .

COPY --from=frontend /app/public/dist /var/www/bookstack/public/dist
RUN ls -la /var/www/bookstack/public/dist 

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 원본 폰트 복사 (Regular / Bold)
COPY fonts/ ./fonts

# fontgen 스테이지에서 만든 italic 결과물 합류
COPY --from=fontgen /fontwork/NanumGothic-Italic.ttf /fontwork/NanumGothic-BoldItalic.ttf /var/www/bookstack/fonts/


RUN echo "alias ll='ls -alF'" >> /root/.bashrc

CMD ["/entrypoint.sh"]
