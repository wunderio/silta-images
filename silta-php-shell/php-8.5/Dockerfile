# Dockerfile for the Drupal container.
FROM wunderio/silta-php-fpm:8.5-fpm-v1

# Switch back to root
USER root

# Pull in security fixes for packages shipped with the base image
RUN apk upgrade --no-cache

# Require openssh with the password authentication bypass fix (Alpine advisory 2026-11-05)
RUN apk add --no-cache 'openssh>=10.3_p1-r2' 'openssh-server>=10.3_p1-r2' bash rsync screen
EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /

# Won't use buildkit yet
RUN chmod 755 /etc/ssh/gitauth_keys.sh

ENTRYPOINT ["/entrypoint.sh"]
