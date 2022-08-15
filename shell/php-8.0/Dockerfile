# Dockerfile for the Drupal container.
FROM wunderio/silta-php-fpm:8.0-fpm-v0.1

# Workaround for base image
# Xdebug: [Config] The setting 'xdebug.remote_enable' has been renamed, see the upgrading guide at https://xdebug.org/docs/upgrade_guide#changed-xdebug.remote_enable (See: https://xdebug.org/docs/errors#CFG-C-CHANGED)
RUN mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.disable \
  && sed -i '/xdebug.remote_enable/d' /usr/local/etc/php/php.ini

# Switch back to root
USER root
RUN apk add --no-cache openssh bash curl rsync screen
EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /

# Won't use buildkit yet
RUN chmod 755 /etc/ssh/gitauth_keys.sh

ENTRYPOINT ["/entrypoint.sh"]