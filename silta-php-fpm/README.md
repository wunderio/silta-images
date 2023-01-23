# Silta Drupal PHP-FPM base images

These images provide a container running php-fpm with a configuration optimised for Drupal projects hosted on [Silta](https://github.com/wunderio/silta). 

The image doesn't contain any PHP code, this will be added by the project-specific Dockerfiles that extend this
image.

silta-php-fpm docker images are based on official php-fpm images https://hub.docker.com/_/php/tags with a few Silta-specific additions.

## Versions
- `7.2-fpm/`: 7.2.34
- `7.3-fpm/`: 7.3.33
- `7.4-fpm/`: 7.4.30
- `8.0-fpm/`: 8.0.22
- `8.1-fpm/`: 8.1.13
