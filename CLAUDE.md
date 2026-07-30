# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Docker image definitions for Wunder's Silta hosting platform. Each image lives in `<image-name>/<variant>/` containing a `Dockerfile` and a `TAGS` file. Images are published to Docker Hub under the `wunderio/` namespace (e.g. `silta-nginx/1.31/` → `wunderio/silta-nginx:1.31-v1.1.0`).

There is no application code, lint, or test framework — validation is "does the Docker image build".

## Commands

```bash
# Build one Dockerfile with full output (also prints node/php version inside the image)
./test-build.sh silta-nginx/1.31/Dockerfile

# Build all Dockerfiles under a path (quiet mode)
./test-build.sh silta-php-fpm
```

## Release model — TAGS files drive everything

The `TAGS` file next to each Dockerfile lists every Docker Hub tag to publish, one per line, typically a cumulative alias chain (e.g. `1.31-v1`, `1.31-v1.1`, `1.31-v1.1.0`).

- **Merging to master with a changed `TAGS` file** triggers `.github/workflows/docker-images.yml`: it builds the image once per tag in the file and pushes each to Docker Hub. A changed Dockerfile alone does NOT trigger a release — you must bump/touch the TAGS file.
- To release a change, add the new patch tag and update the minor/major alias lines in `TAGS` (e.g. add `1.31-v1.1.1`, keep `1.31-v1` and `1.31-v1.1` pointing at it by leaving them in the file).
- The image name comes from the **first** path segment (`silta-nginx/1.31/TAGS` → image `wunderio/silta-nginx`); the tags come only from the file contents, not the directory name.
- After a push to master, the workflow triggers CircleCI validation builds of the downstream repos (`drupal-project-k8s`, `frontend-project-k8s`, `simple-project-k8s`) — but only the projects that consume the changed image, per the routing map in `test-matrix.yml`. Services disabled by default in the charts (redis, memcached, solr, ...) are enabled for the test deployment via extra values files in the project repos (`silta/silta-test-<service>.yml`), selected through the `test_silta_config` CircleCI pipeline parameter. See `docs/image-testing.md` for the flow and the downstream repo contract.

**Pull requests**: `.github/workflows/docker-images-testbuild.yml` test-builds every Dockerfile changed in the PR (build only, nothing pushed).

**CVE report**: `.github/workflows/cve-comparison.yml` is a manual (`workflow_dispatch`) workflow that scans all published images with Docker Scout, rebuilds them locally, and produces a before/after CVE markdown report. Nothing is pushed.

## Downstream consumers — wunderio/charts

These images are pinned in the Helm charts at [wunderio/charts](https://github.com/wunderio/charts) (`drupal`, `frontend`, `simple`, `silta-cluster` values.yaml files). The charts pin **floating alias tags**, not exact patch tags — e.g. `silta-nginx:1.30-v1`, `silta-mariadb:11.4-bc`, `silta-redis:7.4-bc`, `silta-varnish:6-v1`/`7-v1`, `silta-solr:8-v1`, `silta-mongodb:7.0-bc`, `silta-postgresql:16-bc`, `silta-rabbitmq:4.2-bc`, `silta-memcached:1.6-bc`, `silta-mailhog:v1`, `silta-splash:v1`. Re-pushing one of those alias tags therefore changes what every downstream project gets on its next deployment — no chart change needed. Treat alias-tag releases as production releases.

Chart-to-image mapping:
- **drupal chart**: mariadb, memcached, redis, varnish, solr, mailhog (nginx/php/shell images are built per-project from `silta-nginx`, `silta-php-fpm`, `silta-php-shell` bases and passed in as required values).
- **frontend chart**: nginx (default `silta-nginx:1.30-v1`), mariadb, mongodb, postgresql, rabbitmq, redis, varnish, mailhog (app image built from `silta-node` base; shell feature requires it).
- **simple chart**: nginx image passed in per-project.
- **silta-cluster chart**: silta-splash (plus non-this-repo images like silta-traefik, silta-downscaler).
- `silta-cicd/` images are CircleCI builder/executor images used by project pipelines, not referenced by the charts.

## Image conventions

- **`-bc` suffix** (`silta-mariadb/11.4-bc`, `silta-redis/8.4-bc`, etc.) = Bitnami-chart-compatible: official upstream images modified to work with Bitnami Helm charts — user/group changed to uid/gid 1001, `/opt/bitnami/...` symlink trees, and setup scripts fetched from the `bitnami/containers` repo pinned to a commit via `BITNAMI_CONTAINERS_COMMIT`.
- **`silta-cicd/`** variants are CircleCI builder images based on `cimg/php`, named by their toolchain combo (`circleci-php8.4-node24-composer2`). New PHP/Node combos are added as new directories rather than modifying old ones.
- **`silta-nginx/`** builds extra dynamic modules (echo, vts) from source in a builder stage against the exact upstream nginx version, so `NGINX_VERSION` must match the base image tag.
- Multiple versions of each image are maintained side by side as separate directories; old versions are kept for existing projects. Version bumps usually mean editing the pinned base-image tag in the Dockerfile and bumping the TAGS file.
- Dependabot (`.github/dependabot.yml`) watches each image directory for base-image updates; when adding a new image directory, add a corresponding dependabot entry. Some entries ignore major/minor updates because the directory name encodes the version.
