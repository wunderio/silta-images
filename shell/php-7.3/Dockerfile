# Dockerfile for the Drupal container.
FROM eu.gcr.io/silta-images/php:7.3

# Switch back to root
USER root
RUN apk add --no-cache openssh bash curl rsync screen
EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]