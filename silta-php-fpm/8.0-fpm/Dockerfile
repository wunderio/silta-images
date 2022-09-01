# https://hub.docker.com/_/php/tags?page=1&name=8.0
FROM php:8.0.22-fpm-alpine

LABEL maintainer="wunder.io"
LABEL org.label-schema.name="PHP-FPM for Silta environments" \
      org.label-schema.description="PHP-FPM, common plugins and Drush laucher for Silta environments"

RUN apk add --update --no-cache bash openssh-client rsync ssmtp tini \
	# Install mysql client
    mysql-client \
    # Install GNU version of utilities
    findutils coreutils netcat-openbsd \
    # Install pv to show import progress
    pv \
    # libldap for ldap php extension
    libldap \
    libpng \
    libjpeg-turbo \
    gettext \
    libzip \
    libmcrypt \
    libxml2 \
    libxslt \
    libgcrypt \
    libwebp \
    yaml

# PHP modules and build dependencies
RUN apk add --no-cache \
        fcgi \
        imagemagick imagemagick-libs \
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
    && yes '' | pecl install -f apcu-5.1.21 \
    && yes '' | pecl install -f imagick-3.7.0 \
    && yes '' | pecl install -f redis-5.3.7 \
    && yes '' | pecl install -f yaml-2.2.2 \
    && docker-php-ext-enable imagick yaml apcu redis \
    && docker-php-ext-install ldap \
    && docker-php-ext-enable ldap \
    && yes '' | pecl install memcached \
    && docker-php-ext-enable memcached \
    && docker-php-ext-install -j4 bcmath gd gettext mysqli pdo_mysql opcache soap sockets xsl zip \
    && docker-php-ext-configure gd --with-webp --with-jpeg --with-freetype \
    && rm -rf /tmp/pear \
    && apk del .phpize-deps

# Use GNU Iconv
RUN apk add gnu-libiconv --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Backwards-compatibility for projects using an older location.
RUN mkdir -p /var/www/html \
    && ln -s /var/www/html /app

# Add gdpr-dump globally.
# RUN apk add composer; \
#      mkdir -p ~/.composer; \
#      echo '{"minimum-stability": "dev"}' > ~/.composer/composer.json; \
#      composer global require --prefer-dist --ignore-platform-reqs  machbarmacher/gdpr-dump:dev-master; \
#      apk del composer

ENV DRUSH_LAUNCHER_VERSION=0.6.0

RUN set -ex; \
    # Install Drush launcher
    curl -OL https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar; \
    chmod +x drush.phar; \
    mv drush.phar /usr/local/bin/drush;

# Clean up
RUN rm -rf /tmp/* /var/cache/apk/*

RUN set -ex; \ 
    # Create directory for shared files
    mkdir -p -m a+w /app/web/sites/default/files; \
    mkdir -p -m a+w /app/private; \
    mkdir -p -m a+w /app/reference-data; \
    chown -R www-data:www-data /app; \
    # Allow fpm to write in config
    chmod -R o+w /usr/local/etc; \
    # set umask for www-data user
    echo "umask 0002" >> ~www-data/.profile \
    chmod 766 /etc/ssmtp/ssmtp.conf

COPY config/ldap.conf /etc/openldap/ldap.conf
COPY config/w-php-fpm-defaults.conf /usr/local/etc/php-fpm.d/w-php-fpm-defaults.conf
COPY config/w-php-defaults.ini /usr/local/etc/php/conf.d/w-php-defaults.ini
COPY silta /silta

WORKDIR /app/
# Add composer executables to our path.
ENV PATH="/home/.composer/vendor/bin:${PATH}"

ENTRYPOINT [ "/sbin/tini", "--", "/silta/entrypoint.sh" ]
CMD ["php-fpm", "-F", "-R"]
