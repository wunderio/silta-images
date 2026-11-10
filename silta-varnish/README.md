# Silta Varnish docker image for Drupal projects

Docker image based on official varnish image.

Varnish 6.x image specifics:

- Varnish 6.0 LTS (from 6-v1.1; 6-v1.0 was the EOL 6.6)
- based on Debian
- runs on port 80
- runs as root

Varnish 7.x image specifics:

- based on Alpine
- runs on port 8080
- runs as varnish

## Usage

docker pull wunderio/silta-varnish.

## Resources

Varnish repository: https://github.com/varnish/docker-varnish
Varnish images: https://hub.docker.com/_/varnish
