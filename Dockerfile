# ═══════════════════════════════════════════════════════════════
#  WordPress 6.9.4 · PHP 8.3 · Apache
# ═══════════════════════════════════════════════════════════════
FROM php:8.3-apache

LABEL maintainer="Raphaël – HES-SO Valais"
LABEL description="WordPress 6.9.4, PHP 8.3, Apache, WPGraphQL, AIOSEO Migration, REST API"

# ── Versions ────────────────────────────────────────────────────
ARG WP_VERSION=6.9.4
ARG WP_CLI_VERSION=2.11.0

# ── System packages ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    mariadb-client \
    curl \
    unzip \
    less \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# ── PHP extensions ───────────────────────────────────────────────
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        mbstring \
        mysqli \
        opcache \
        pdo_mysql \
        xml \
        zip

# ── Apache config ────────────────────────────────────────────────
RUN a2enmod rewrite headers expires deflate
COPY config/apache/wordpress.conf /etc/apache2/sites-available/000-default.conf

# ── PHP config ───────────────────────────────────────────────────
COPY config/php/php.ini /usr/local/etc/php/conf.d/wordpress.ini

# ── WP-CLI ──────────────────────────────────────────────────────
RUN curl -fsSL \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
        -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp \
    && wp --info --allow-root

# ── WordPress core ───────────────────────────────────────────────
RUN curl -fsSL \
        "https://wordpress.org/wordpress-${WP_VERSION}.tar.gz" \
        -o /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1 \
    && rm /tmp/wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# ── Entrypoint ───────────────────────────────────────────────────
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
