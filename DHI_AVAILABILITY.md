# DHI Image Availability & Migration Strategy for silta-images

Last checked: 2026-03-30

Registry: `dhi.io`

## Migration priorities

The primary driver for DHI migration is **replacing Bitnami images** (Broadcom moved Bitnami to paid, $50-72k/yr). For non-Bitnami images that use official upstream bases (PHP, nginx, Alpine), a simple **rebuild with updated base tags** is often sufficient to eliminate most CVEs — no DHI rewrite needed.

## Already migrated to DHI

| silta image | DHI base | Versions migrated | Original base | Reason |
|-------------|----------|-------------------|---------------|--------|
| silta-redis | `dhi.io/redis` | 7.2, 7.4, 8.0, 8.2, 8.4, 8.6 | Bitnami | Bitnami dependency removal — required |
| silta-node | `dhi.io/node` | 20, 22, 24 | `node:*-alpine` (official) | **Retrospective: was not Bitnami-based.** DHI migration was unnecessary — a rebuild of the Alpine images would have been sufficient. See CVE comparison below. The debian13 variants work but carry 47 LOW noise CVEs from Debian triaging. Consider whether to keep them or revert to rebuilt Alpine. |

## Bitnami images — DHI migration required

These are the images where DHI migration is actively needed because of the Bitnami dependency.

| silta image | DHI image name | Versions available | Notes |
|-------------|---------------|-------------------|-------|
| silta-postgresql | `dhi.io/postgres` | 14, 16, 17, 18 | All current silta versions available. DHI uses `postgres` not `postgresql`. |
| silta-rabbitmq | `dhi.io/rabbitmq` | 4.1, 4.2 | 3.8 is very old / likely unavailable. |
| silta-memcached | `dhi.io/memcached` | 1.6 | Also found as `1-debian13-dev`. |
| silta-mongodb | `dhi.io/mongodb` | 8.0, 8.2 | 6.0 and 7.0 not found. |

## Non-Bitnami images — rebuild is sufficient

These images use official upstream bases. CVE analysis (2026-03-30) shows that most vulnerabilities come from stale packages in old builds, not from the base image itself. Simply rebuilding with updated base tags eliminates the majority of CVEs without a full DHI rewrite.

### silta-node

**Current state:** `node:*-alpine` base (official Node images). Not Bitnami. DHI Debian variants were created (`*-debian13-v2`) but were unnecessary.

**Rebuild analysis:** `node:22-alpine` fresh base has 6 CVEs (0C, 1H) — better than the DHI Debian migration which has 51 CVEs (0C, 1H, 47L Debian noise). Same HIGH count either way.

**Recommendation:** Rebuild Alpine images. Consider deprecating the `*-debian13-v2` variants or keeping them only if Debian is preferred for other reasons (consistency, tooling).

### silta-php-fpm

**Current state:** `php:8.3.30-fpm-alpine` base, 86 CVEs (1C, 30H, 42M, 6L) on the published image.

**Rebuild analysis:** The official `php:8.3.30-fpm-alpine` base itself has only 22 CVEs (0C, 8H, 12M, 2L). Most of the 86 CVEs in the published image are from stale Alpine packages baked into old builds. A fresh rebuild would bring it down to ~22 base + whatever our added packages contribute.

**DHI investigation (2026-03-30):**
- DHI has PHP FPM variants: `dhi.io/php:8.3-alpine3.22-fpm` (14 CVEs: 0C, 2H, 10M, 2L) and `dhi.io/php:8.3-debian13-fpm` (25 CVEs: 0C, 1H, 0M, 24L).
- DHI FPM images are stripped runtime-only (nonroot UID 65532, no apk/bash/shell tools, no php CLI). Cannot build on top of them directly.
- DHI dev images (`8.3-alpine3.22-dev`, `8.3-debian13-dev`) have build tools but **no php-fpm** — PHP compiled CLI-only without `--enable-fpm`.
- DHI migration would require either recompiling PHP from source with `--enable-fpm` in the dev image, or a complex multi-stage build (build in dev, COPY into fpm). Both are high effort.
- Available DHI PHP tags: `8.3-debian13-fpm`, `8.3-alpine3.22-fpm`, plus `-dev`, `-fips`, `-fips-dev` variants. All versions: 8.1, 8.2, 8.3, 8.4, 8.5.

**Recommendation:** Rebuild with current Alpine base. The CVE reduction from 86→~30 is significant and immediate. DHI migration is possible but high complexity for marginal gain over a fresh rebuild.

### silta-nginx

**Current state:** Official `nginx` / `nginx-unprivileged` base with multi-stage build for echo+VTS modules and Fastly Signal Sciences WAF.

**Recommendation:** Rebuild with updated nginx base. DHI available (`dhi.io/nginx:1.28, 1.29`) but the module compilation and WAF install would need significant rework for Debian. Only worth doing if the rebuild CVE count is unsatisfactory.

### silta-rsync, silta-backup, silta-proxy

**Current state:** Official `alpine:3.23` base. Very simple images.

**Recommendation:** Rebuild with updated Alpine base. DHI `alpine-base` available (`3.22, 3.23`) but these are already minimal images — benefit is marginal.

### silta-splash

**Current state:** `nginx-unprivileged` base with only COPY of static files.

**Recommendation:** Rebuild. Trivially could swap to `dhi.io/nginx:1.28` runtime (already unprivileged, identical layout) but rebuild is fine.

### silta-mariadb

**Current state:** Official `mariadb:*` base.

**DHI status:** Not available. No `dhi.io/mariadb` exists. Rebuild with updated official base.

### silta-varnish

**Current state:** `varnish:7.7.3-alpine` (v7), `varnish:6.6` (v6). Thin wrapper (startup script + secret).

**DHI status:** Not available. v6 is EOL. Official varnish image is already purpose-built and minimal. Rebuild only.

## Not yet checked

| silta image | Current base | Notes |
|-------------|-------------|-------|
| silta-php-shell | PHP official images | Depends on silta-php-fpm approach |
| silta-cicd | circleci images | Large image, 23 variants |
| silta-solr | solr / geerlingguy | |
| silta-mailhog | mailhog | |
| silta-robot-framework | custom | |

## CVE comparison summary (2026-03-30)

### silta-node

| Image | Total | C | H | M | L |
|-------|-------|---|---|---|---|
| Published `silta-node:22-alpine-v1` (stale) | 34 | 0 | 19 | 12 | 3 |
| Published `silta-node:20-alpine-v1` (stale) | 28 | 0 | 13 | 11 | 4 |
| DHI migrated `silta-node:22-debian13-v2` | 51 | 0 | 1 | 3 | 47 |
| DHI migrated `silta-node:24-debian13-v2` | 51 | 0 | 1 | 3 | 47 |
| Fresh base `node:22-alpine` (rebuild) | 6 | 0 | 1 | 4 | 1 |
| Fresh base `node:24-alpine` (rebuild) | 20 | 0 | 8 | 3 | 1 |

Node 22 Alpine rebuild (6 CVEs, 1H) is better than the DHI Debian migration (51 CVEs, 1H) — same HIGH count but far less noise. Node 24 Alpine has more HIGHs (8) because upstream hasn't patched everything yet, but this will improve with time.

### silta-php-fpm

| Image | Total | C | H | M | L |
|-------|-------|---|---|---|---|
| Published `silta-php-fpm:8.3-fpm` (stale) | 86 | 1 | 30 | 42 | 6 |
| Fresh base `php:8.3.30-fpm-alpine` (rebuild) | 22 | 0 | 8 | 12 | 2 |
| DHI `php:8.3-alpine3.22-fpm` | 14 | 0 | 2 | 10 | 2 |
| DHI `php:8.3-alpine3.22-dev` | 34 | 0 | 10 | 20 | 2 |
| DHI `php:8.3-debian13-fpm` | 25 | 0 | 1 | 0 | 24 |

## DHI probe notes

- 500/502/504 errors from dhi.io are common (flaky registry). A single failure doesn't confirm absence — retry if needed.
- "Not Found" or "no such manifest" is definitive — the image/tag does not exist.
- Always check both `<name>` and common aliases (e.g., `postgres` vs `postgresql`, `mongo` vs `mongodb`).
- DHI PHP images install PHP at `/opt/php-8.3/` (not `/usr/local/`). No `docker-php-ext-install` helpers — uses `phpize`/`pecl` directly.
- DHI FPM images are nonroot (UID 65532), stripped of package managers and shells. Dev images run as root with full build toolchain.
- DHI Alpine images use Alpine 3.22, DHI Debian images use Debian 13 (Trixie).
