# Silta Drupal PHP-FPM base images

These images provide a container running php-fpm with a configuration optimised for Drupal projects hosted on [Silta](https://github.com/wunderio/silta). 

The image doesn't contain any PHP code, this will be added by the project-specific Dockerfiles that extend this
image.

silta-php-fpm docker images are based on official php-fpm images https://hub.docker.com/_/php/tags with a few Silta-specific additions.

## Versions
- `7.4-fpm/`: 7.4.33
- `8.2-fpm/`: 8.2.35
- `8.3-fpm/`: 8.3.36
- `8.4-fpm/`: 8.4.27
- `8.5-fpm/`: 8.5.12

## Elasticdump

[elasticdump](https://github.com/elasticsearch-dump/elasticsearch-dump) (and the Node.js runtime it needs) is no longer included in these images. Projects that need it should install it in their own Dockerfile. The recommended place is `silta/shell.Dockerfile`, so the containers serving web traffic stay free of Node.js:

```dockerfile
FROM wunderio/silta-php-shell:php8.3-v1

# Elasticdump for importing/exporting Elasticsearch data
RUN apk add --no-cache nodejs npm \
    && npm install -g elasticdump@6 \
    && npm cache clean --force \
    && apk del npm

COPY --chown=www-data:www-data . /app
```

If you add it to `silta/php.Dockerfile` instead, place the `RUN` before `USER www-data`, otherwise `apk` fails due to missing permissions.
Node.js comes from the Alpine repositories of the base image, so the project is responsible for rebuilding to pick up Node.js security updates.
