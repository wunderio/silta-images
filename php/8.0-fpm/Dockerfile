# https://hub.docker.com/r/amazeeio/php/tags?page=1&name=8.0
FROM amazeeio/php:8.0-fpm-20.12.0

LABEL maintainer="wunder.io"
LABEL org.label-schema.name="Alpine with PHP8-FPM and Drush launcher" \
      org.label-schema.description="PHP8-FPM, common plugins and Drush laucher"

# Workaround for base image
COPY entrypoints/90-php-config-alter.sh /lagoon/entrypoints/90-php-config-alter.sh

# Added due to https://github.com/drush-ops/drush/issues/4009  
RUN apk add --update --no-cache bash openssh-client rsync

# PHP modules and build dependencies
RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS libtool imagemagick-dev openldap-dev libmemcached-dev \
    && docker-php-ext-install ldap \
    && docker-php-ext-enable ldap \
    && yes '' | pecl install memcached \
    && docker-php-ext-enable memcached \
    && apk del .phpize-deps \
    && apk add --no-cache --virtual .imagick-runtime-deps imagemagick libmemcached

# Use GNU Iconv
RUN apk add gnu-libiconv --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

COPY config/ldap.conf /etc/openldap/ldap.conf
COPY config/w-php-fpm-defaults.conf /usr/local/etc/php-fpm.d/w-php-fpm-defaults.conf
COPY config/w-php-defaults.ini /usr/local/etc/php/conf.d/w-php-defaults.ini

ENV DRUSH_LAUNCHER_VERSION=0.6.0

# Backwards-compatibility for projects using an older location.
RUN mkdir -p /var/www/html && ln -s /var/www/html /app

# Add gdpr-dump globally.
RUN apk add composer; \
     mkdir -p ~/.composer; \
     echo '{"minimum-stability": "dev"}' > ~/.composer/composer.json; \
     composer global require --prefer-dist machbarmacher/gdpr-dump:dev-master; \
     apk del composer

RUN set -ex; \
    # Install mysql client
    apk add mysql-client; \
    # Install GNU version of utilities
    apk add findutils coreutils netcat-openbsd; \
    # Install pv to show import progress
    apk add pv; \
    # Install Drush launcher
    curl -OL https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar; \
    chmod +x drush.phar; \
    mv drush.phar /usr/local/bin/drush; \
    \
    # Create directory for shared files
    mkdir -p -m a+w /app/web/sites/default/files; \
    mkdir -p -m a+w /app/private; \
    mkdir -p -m a+w /app/reference-data; \
    chown -R www-data:www-data /app

WORKDIR /app/
# Add composer executables to our path.
ENV PATH="/home/.composer/vendor/bin:${PATH}"
