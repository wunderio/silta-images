# Dockerfile for the Drupal container.
FROM wunderio/silta-php-fpm:8.2-fpm-v1

# Switch back to root
USER root
RUN apk add --no-cache openssh bash curl "rsync>~3.4.0" screen
EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /

# Won't use buildkit yet
RUN chmod 755 /etc/ssh/gitauth_keys.sh

ENTRYPOINT ["/entrypoint.sh"]
