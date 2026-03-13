FROM php:8.2-fpm

# Install system dependencies & PHP extensions commonly used by Laravel
RUN apt-get update && apt-get install -y \
    git zip unzip libzip-dev libicu-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql intl gd zip \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy source first (simpler; ensures artisan exists for composer scripts)
COPY . .
# Install PHP dependencies
RUN composer install --no-dev --no-interaction --prefer-dist

# Ensure storage/bootstrap writable
RUN chown -R www-data:www-data storage bootstrap/cache

# PHP-FPM listens on 9000
EXPOSE 9000
CMD ["php-fpm"]
