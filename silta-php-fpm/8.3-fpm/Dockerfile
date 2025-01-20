# https://hub.docker.com/_/php/tags?page=1&name=8.3
FROM php:8.3.14-fpm-alpine3.20

LABEL maintainer="wunder.io"
LABEL org.label-schema.name="PHP-FPM for Silta environments" \
      org.label-schema.description="PHP-FPM and common plugins for Silta environments"

RUN apk add --update --no-cache bash openssh-client "rsync>3.4.0" ssmtp tini \
	# Install mysql client
    'mariadb-client=10.11.10-r0' \
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
    libwebp \
    yaml \
    tzdata

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
        # for webp
        libwebp-dev \
        postgresql-dev \
        # for yaml
        yaml-dev \
        # for imagemagick
        imagemagick-dev \
        # https://github.com/php/php-src/issues/8681#issuecomment-1144062769
        # https://github.com/docker-library/php/issues/888
        linux-headers \
    && yes '' | pecl install -f apcu-5.1.21 \
    # imagick: Install error "Unterminated preprocessor conditions" in php 8.3
    # https://github.com/Imagick/imagick/issues/640
    # && yes '' | pecl install -f imagick-3.7.0 \
    && curl -fsSL https://github.com/Imagick/imagick/archive/944b67fce68bcb5835999a149f917670555b6fcb.tar.gz | tar xvz -C /tmp \
    && yes '' | pecl install /tmp/imagick-944b67fce68bcb5835999a149f917670555b6fcb/package.xml \
    && yes '' | pecl install -f redis-5.3.7 \
    && yes '' | pecl install -f yaml-2.2.2 \
    && docker-php-ext-enable imagick yaml apcu redis \
    && docker-php-ext-install ldap \
    && docker-php-ext-enable ldap \
    && yes '' | pecl install memcached \
    && docker-php-ext-enable memcached \
    && docker-php-ext-configure gd --with-webp --with-jpeg --with-freetype \
    && docker-php-ext-install -j$(nproc) bcmath gd gettext mysqli pdo_mysql opcache soap sockets xsl zip \
    && rm -rf /tmp/pear \
    && apk del .phpize-deps

# Use GNU Iconv
RUN apk add gnu-libiconv --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Backwards-compatibility for projects using an older location.
RUN mkdir -p /var/www/html \
    && ln -s /var/www/html /app

# Add Smile-SA/gdpr-dump for sanitized reference data creation.
ENV SA_GDPR_DUMP_VERSION=4.0.1
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
