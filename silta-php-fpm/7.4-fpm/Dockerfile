# https://hub.docker.com/_/php/tags?page=1&name=7.4
FROM php:7.4.33-fpm-alpine

LABEL maintainer="wunder.io"
LABEL org.label-schema.name="PHP-FPM for Silta environments" \
      org.label-schema.description="PHP-FPM and common plugins for Silta environments"

RUN apk add --update --no-cache bash openssh-client rsync ssmtp tini \
    # Install MariaDB Connector/C
    mariadb-connector-c \
    # Install mysql client
    mysql-client \
    # Install GNU version of utilities
    findutils coreutils netcat-openbsd \
    # Install pv to show import progress
    pv \
    # libldap for ldap php extension
    libldap \
    libpng \
    libjpeg \
    libjpeg-turbo \
    gettext \
    libzip \
    libmcrypt \
    libxml2 \
    libxslt \
    libgcrypt \
    yaml \
    autoconf \
    pkgconfig \
    tzdata

# Requires 1.3.2+ to fix CVE-2023-4863
RUN apk add libwebp libwebp-dev --update-cache --repository "http://dl-cdn.alpinelinux.org/alpine/v3.18/main" --allow-untrusted \
    && apk version libwebp

# PHP modules and build dependencies
RUN apk add --no-cache \
        fcgi \
        imagemagick imagemagick-libs \
        graphicsmagick \
        libmemcached \
        && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
        libtool \
        openldap-dev \
        zlib-dev \
        libzip-dev \
        # memcached
        libmemcached-dev \
        # for gd
        libpng-dev \
        jpeg-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        # for gettext
        gettext-dev \
        # for mcrypt
        libmcrypt-dev \
        # for soap
        libxml2-dev \
        # for xsl
        libxslt-dev \
        libgcrypt-dev \
        postgresql-dev \
        # for yaml
        yaml-dev \
        # for imagemagick
        imagemagick-dev \
    && yes '' | pecl install -f apcu-5.1.21 \
    && yes '' | pecl install -f imagick-3.7.0 \
    && yes '' | pecl install -f redis-5.3.7 \
    && yes '' | pecl install -f yaml-2.2.2 \
    && docker-php-ext-enable imagick yaml apcu redis \
    && docker-php-ext-install ldap \
    && docker-php-ext-enable ldap \
    && yes '' | pecl install memcached \
    && docker-php-ext-enable memcached \
    && docker-php-ext-install -j$(nproc) bcmath gettext mysqli pdo_mysql opcache soap sockets xsl zip \
    && rm -rf /tmp/pear \
    && docker-php-ext-install gd \
    && docker-php-ext-configure gd --enable-gd --with-webp --with-jpeg --with-freetype \
    && apk del .phpize-deps

# Use GNU Iconv
RUN apk add gnu-libiconv --update-cache --repository "http://dl-cdn.alpinelinux.org/alpine/v3.18/main" --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Backwards-compatibility for projects using an older location.
RUN mkdir -p /var/www/html \
    && ln -s /var/www/html /app

# Add Smile-SA/gdpr-dump for sanitized reference data creation.
ENV SA_GDPR_DUMP_VERSION=3.1.0
RUN wget https://github.com/Smile-SA/gdpr-dump/releases/download/${SA_GDPR_DUMP_VERSION}/gdpr-dump.phar -O /usr/local/bin/gdpr-dump \
    && chmod +x /usr/local/bin/gdpr-dump \
    && gdpr-dump --version

# Elasticdump for importing/exporting Elasticsearch data
RUN apk add nodejs \
    && apk add --no-cache --virtual .build-deps npm \
    && npm install -g elasticdump@v6 \
    && npm cache clean --force \
    && apk del .build-deps

# Clean up
RUN apk del autoconf pkgconfig
RUN rm -rf /tmp/* /var/cache/apk/*

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/silta \
    ENV=/silta/.bashrc \
    BASH_ENV=/silta/.bashrc

COPY config/ssmtp.conf /etc/ssmtp/ssmtp.conf

RUN set -ex; \ 
    # Create directory for shared files
    mkdir -p -m a+w /app/web/sites/default/files; \
    mkdir -p -m a+w /app/private; \
    mkdir -p -m a+w /app/reference-data; \
    chown -R www-data:www-data /app; \
    # Allow fpm to write in config
    chmod -R o+w /usr/local/etc; \
    chmod 766 /etc/ssmtp/ssmtp.conf

COPY config/ldap.conf /etc/openldap/ldap.conf
COPY config/www.fpm.conf /usr/local/etc/php-fpm.d/www.fpm.conf
COPY config/w-php-defaults.ini /usr/local/etc/php/conf.d/w-php-defaults.ini
COPY silta /silta
COPY silta/entrypoints/10-env.sh /etc/profile.d/10-env.sh

# Replaces drush launcher with a static path
ENV PATH="$PATH:/app/vendor/drush/drush/"
RUN echo $PATH

WORKDIR /app/

ENTRYPOINT [ "/sbin/tini", "--", "/silta/entrypoint.sh" ]
CMD ["php-fpm", "-F", "-R"]
