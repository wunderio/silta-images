# Silta images

Image tags listed at `*/*/TAGS`

## Image publishing trigger

Docker image publishing is triggered by GitHub Actions only when both are true:
- the push target branch is `master`
- at least one `*/*/TAGS` file changed in that push

If you change `TAGS` on a feature branch, the publish workflow does not run
until that change is merged/pushed to `master`.

- `silta-cicd/`: CI builder images
- `silta-nginx/`: Drupal Nginx images
- `silta-node/`: Frontend NodeJS images
- `silta-openresty/`: Drupal Nginx/Openresty images
- `silta-php-fpm/`: Drupal PHP images
- `silta-php-shell/`: Drupal shell images
- `silta-mailhog/`: Official mailhog image, with extra modifications.
- `silta-proxy/`: An HTTP proxy based on tinyproxy used to provide a static egress IP.
- `silta-varnish/`: Drupal varnish images
- `silta-backup/`: Backup helper images
- `silta-rsync/`: Very basic alpine container with rsync binary
- `silta-solr/`: Apache Solr search images
- `silta-splash/`: Static page for default service

Bitnami chart compatible images:
- `silta-mariadb/`: MariaDB images
- `silta-memcached/`: Memcached image
- `silta-mongodb/`: MongoDB images
- `silta-postgresql/`: PostgreSQL images
- `silta-rabbitmq/`: RabbitMQ images
- `silta-redis/`: Redis images

## DHI (Docker Hardened Images)

Some images have an opt-in `*-dhi` sibling variant built on Docker Hardened
Images instead of the Bitnami base image, reducing CVE count. Note this
replaces the Bitnami *base image* only - the redis and mongodb variants still
vendor and run Bitnami's own entrypoint/setup scripts (`/opt/bitnami/scripts`)
on top of it, so the Bitnami runtime dependency isn't fully gone.
Currently available DHI variants:
- `silta-redis/`: `7.4-dhi`, `8.4-dhi`, `8.6-dhi`, `8.8-dhi`, `8.10-dhi`
- `silta-mongodb/`: `8.3-dhi`
- `silta-node/`: `22-alpine-dhi`, `24-alpine-dhi`, `26-alpine-dhi`

## Automation

See automation folder for Scripts and docs that keep this repo's version pins from silently drifting.

- `bump-dependabot-image.sh` / `bump-all-dependabot-images.sh`: a dependabot
  image-bump PR only touches `FROM`. These add the rest of what a release
  actually needs - the `TAGS` bump that triggers the publish workflow, any
  secondary version `ENV`/`ARG` that duplicates the `FROM` tag, and README
  version tables. See `dependabot-image-bumps.md`.
- `bump-cicd-tool-versions.py`: `silta-cicd/*/Dockerfile` installs Node.js,
  Yarn, Helm and (on the hardened variants) the AWS CLI via a hand-pinned
  `ENV` + `curl`, which Dependabot never sees at all. This checks each pin
  against upstream and bumps it (plus its `TAGS` counter) within the same
  major line. See `cicd-tool-version-bumps.md`.
- `image-testing.md`: how a pushed image gets exercised by a downstream
  project's test pipeline (see `test-matrix.yml`).

