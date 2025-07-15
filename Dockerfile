# ─── Stage 1: build GD + Composer deps on Alpine ───
FROM php:8.3-cli-alpine AS builder
WORKDIR /app

# 1) Install build tools, GD libs, git & curl
RUN apk add --no-cache \
      libpng-dev \
      libjpeg-turbo-dev \
      freetype-dev \
      autoconf \
      build-base \
      git \
      curl

# 2) Configure & build the GD extension
RUN docker-php-ext-configure gd \
      --with-jpeg=/usr/include/ \
      --with-freetype=/usr/include/ \
 && docker-php-ext-install gd

# 3) Copy in only what Composer needs, including your local patches
COPY composer.json composer.lock patches/ ./

# 4) Install Composer and your PHP deps (with patches)
RUN curl -sS https://getcomposer.org/installer \
      | php -- --install-dir=/usr/local/bin --filename=composer \
 && composer install --no-dev --optimize-autoloader --no-interaction

# 5) Remove build deps to shrink the image
RUN apk del autoconf build-base git curl

# ─── Stage 2: final Drupal image ───
FROM drupal:10-php8.3-apache
WORKDIR /var/www/html
USER root

# 1) Copy the built GD extension + ini from the Alpine builder
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-*/gd.so \
                     /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/docker-php-ext-gd.ini \
                     /usr/local/etc/php/conf.d/

# 2) Copy in your Composer vendor folder
COPY --from=builder /app/vendor ./vendor

# 3) Copy your web root
ARG WEB_DIR=production/web
COPY ${WEB_DIR}/ ./

# 4) Fix permissions
RUN chown -R www-data:www-data sites \
 && chmod -R 755 sites






 
# ─── Stage 1: builder on Debian Bookworm ───
# FROM php:8.3-cli-bookworm AS builder
# WORKDIR /app
# USER root

# # 1) Rewrite every APT list to HTTPS
# # 2) Update & install everything (dev-libs + keyring + git/unzip) even if signatures are invalid
# RUN find /etc/apt -type f -name '*.list' \
#       -exec sed -i 's|http://deb.debian.org|https://deb.debian.org|g' {} + \
#  && apt-get update -o Acquire::AllowInsecureRepositories=true \
#  && apt-get install -y --allow-unauthenticated --no-install-recommends \
#       ca-certificates \
#       apt-transport-https \
#       gnupg2 \
#       debian-archive-keyring \
#       git \
#       unzip \
#       zip \
#       libpng-dev \
#       libjpeg-dev \
#       libfreetype-dev \
#  && rm -rf /var/lib/apt/lists/*

# # 2) Build the GD extension
# RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
#  && docker-php-ext-install gd

# # 3) Install Composer
# RUN curl -sS https://getcomposer.org/installer \
#       | php -- --install-dir=/usr/local/bin --filename=composer

# # 4) Copy composer files + patches, then install PHP deps
# COPY composer.json composer.lock patches/ ./
# RUN composer install --no-dev --optimize-autoloader --no-interaction

# # ─── Stage 2: final Drupal image ───
# FROM drupal:10-php8.3-apache
# WORKDIR /var/www/html
# USER root

# # Copy GD extension + ini
# COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-*/gd.so  /usr/local/lib/php/extensions/
# COPY --from=builder /usr/local/etc/php/conf.d/docker-php-ext-gd.ini      /usr/local/etc/php/conf.d/

# # Copy vendor + webroot
# COPY --from=builder /app/vendor ./vendor
# ARG WEB_DIR=production/web
# COPY ${WEB_DIR}/ ./

# RUN chown -R www-data:www-data sites \
#  && chmod -R 755 sites









# ─── Stage 1: build GD + install Composer deps ───
# FROM php:8.3-cli-alpine AS builder
# WORKDIR /app
# USER root

# # 1) Install build-deps + GD libs + git + curl
# RUN apk add --no-cache \
#       libpng-dev \
#       libjpeg-turbo-dev \
#       freetype-dev \
#       autoconf \
#       build-base \
#       git \
#       curl

# # 2) Build the GD extension
# RUN docker-php-ext-configure gd \
#       --with-jpeg=/usr/include/ \
#       --with-freetype=/usr/include/ \
#  && docker-php-ext-install gd

# # 3) Copy in just the files Composer needs: 
# #    - your composer.json & lockfile 
# #    - the folder where your .patch files live
# COPY composer.json composer.lock patches/ ./

# # 4) Install Composer itself, then your PHP deps (including patch application)
# RUN curl -sS https://getcomposer.org/installer \
#       | php -- --install-dir=/usr/local/bin --filename=composer \
#  && composer install --no-dev --optimize-autoloader --no-interaction

# # 5) Clean up all build-only tooling to free up space
# RUN apk del autoconf build-base git curl

# # ─── Stage 2: runtime Drupal image ───
# FROM drupal:10-php8.3-apache
# WORKDIR /var/www/html
# USER root

# # Copy the compiled GD extension + ini from the Alpine builder
# COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-*/gd.so \
#                      /usr/local/lib/php/extensions/
# COPY --from=builder /usr/local/etc/php/conf.d/docker-php-ext-gd.ini \
#                      /usr/local/etc/php/conf.d/

# # Copy in your Composer-installed vendor dir
# COPY --from=builder /app/vendor ./vendor

# # Then your actual web-root
# ARG WEB_DIR=production/web
# COPY ${WEB_DIR}/ ./

# # Fix ownership/permissions
# RUN chown -R www-data:www-data sites \
#  && chmod -R 755 sites