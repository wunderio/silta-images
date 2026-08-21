# DHI Image Availability & Migration Strategy for silta-images

Last checked: 2026-03-30 — except silta-redis and silta-mongodb, rechecked
2026-08-21 (see their sections below; the older notes elsewhere in this file have
not been re-verified since March).

Registry: `dhi.io`

## Migration priorities

The primary driver for DHI migration is **replacing Bitnami images** (Broadcom moved Bitnami to paid, $50-72k/yr). For non-Bitnami images that use official upstream bases (PHP, nginx, Alpine), a simple **rebuild with updated base tags** is often sufficient to eliminate most CVEs — no DHI rewrite needed.

## Already migrated to DHI

| silta image | DHI base | Versions migrated | Original base | Reason |
|-------------|----------|-------------------|---------------|--------|
| silta-redis | `dhi.io/redis` | 7.4, 8.4, 8.6, 8.8, 8.10 (`*-dhi`, `-compat` base) | Bitnami | Bitnami dependency removal — required. The earlier `*-debian13` variants were removed 2026-08-21 in favour of `-compat`; see below. |
| silta-node | `dhi.io/node` | 20, 22, 24 | `node:*-alpine` (official) | **Retrospective: was not Bitnami-based.** DHI migration was unnecessary — a rebuild of the Alpine images would have been sufficient. See CVE comparison below. The debian13 variants work but carry 47 LOW noise CVEs from Debian triaging. Consider whether to keep them or revert to rebuilt Alpine. |

## silta-redis DHI catalog status

Checked 2026-08-20 against the public catalog index, which lists every published
tag without needing registry credentials:

```
https://github.com/docker-hardened-images/catalog/tree/main/image/redis/debian-13
https://raw.githubusercontent.com/docker-hardened-images/catalog/main/image/redis/debian-13/<minor>-compat.yaml
```

`debian-13` `-compat` flavors currently published (the flavor our `*-dhi`
variants build on — it ships bash/coreutils/sed/grep/procps):

| redis line | `-compat` | current patch | silta variant | notes |
|-----------|-----------|---------------|---------------|-------|
| 7.4  | yes | 7.4.11 | `7.4-dhi`  | **EOL 2026-11-30** — only line with an announced EOL |
| 8.0  | **no** | — | — | absent from the catalog entirely |
| 8.2  | **no** | — | — | absent from the catalog entirely |
| 8.4  | yes | 8.4.6  | `8.4-dhi`  | |
| 8.6  | yes | 8.6.6  | `8.6-dhi`  | |
| 8.8  | yes | 8.8.2  | `8.8-dhi`  | |
| 8.10 | yes | 8.10.1 | `8.10-dhi` | newest line |

Notes:

- **8.0 and 8.2 have no `-compat` flavor** — neither line appears in the catalog
  index for `debian-13`, `alpine-3.23`, or `alpine-3.24`.
  *Correction (2026-08-21):* an earlier revision of this file claimed the
  `8.{0,2}-debian13-dev` base tags were gone too. That was wrong. The catalog
  *index* omits those lines, but the *registry* still serves every
  `7.2/8.0/8.2-debian13-dev` tag — verified with
  `docker buildx imagetools inspect`. Absence from the index is not proof of
  absence from the registry; check the registry before concluding a tag is dead.
- **Pin the minor tag, not the patch.** `8.4-dhi` originally pinned
  `8.4.4-compat`; DHI withdrew that tag when 8.4.6 superseded it, breaking the
  build. All `*-dhi` variants now use `<minor>-compat` so patch releases are
  picked up without a code change.
- The vendored Bitnami overlay in `rootfs/` is distro- and version-agnostic and
  is byte-identical across every `*-dhi` variant.

All five `*-dhi` variants were built and smoke-tested on 2026-08-20: each starts,
answers `PING`, serves a SET/GET round-trip, and runs as uid 1001. Reported
`redis_version` matched the pinned line exactly (7.4.11 / 8.4.6 / 8.6.6 / 8.8.2 /
8.10.1).

### `*-debian13` variants removed (2026-08-21)

The six `silta-redis/*-debian13` directories (7.2, 7.4, 8.0, 8.2, 8.4, 8.6, built
on `dhi.io/redis:*-debian13-dev`) were deleted. Docker Scout reports the
`-compat` runtime images carry substantially fewer vulnerabilities than the
`-debian13` builds, which is unsurprising: `-debian13-dev` is a *dev* base that
ships a compiler and build tooling, whereas `-compat` is a runtime base carrying
only bash/coreutils/sed/grep/mawk/procps on top of redis.

Consequences to be aware of:

- **redis 8.0 and 8.2 now have no image at all.** They existed only as
  `*-debian13`, and DHI publishes no 8.0/8.2 `-compat`, so they cannot be
  reproduced as `-dhi`. Anything pinning `8.{0,2}-debian13-v2*` must move to
  8.4+ (or 7.4). Already-pushed tags stay in the registry, but nothing rebuilds
  or patches them.
- **redis 7.2 falls back to `7.2-bc`, i.e. Bitnami-only** — the one thing this
  migration exists to eliminate. DHI has no 7.2 line, so a supported non-Bitnami
  7.2 is not currently possible; moving 7.2 consumers to 7.4+ is the only clean
  path.
- ~~No image in the repo declares a `HEALTHCHECK` any more.~~ **Fixed
  2026-08-21** — see "Healthcheck gate" below.

Version coverage after the removal:

| redis line | remaining variants |
|-----------|--------------------|
| 6.2  | `6.2-bc` (Bitnami) |
| 7.0  | `7.0-bc` (Bitnami) |
| 7.2  | `7.2-bc` (Bitnami — no DHI line exists) |
| 7.4  | `7.4-bc`, `7.4-dhi` |
| 8.0  | **none** |
| 8.2  | **none** |
| 8.4  | `8.4-bc`, `8.4-dhi` |
| 8.6  | `8.6-dhi` |
| 8.8  | `8.8-dhi` |
| 8.10 | `8.10-dhi` |

## Healthcheck gate

The `Build and push images` step in `.github/workflows/docker-images.yml` builds
each image to a throwaway tag, and — when the image declares a `HEALTHCHECK` —
starts a container and refuses to push unless it reports `healthy`.

Removing the `*-debian13` variants exposed a flaw in that design: those
Dockerfiles were the only ones in the repo declaring a `HEALTHCHECK`, so the gate
quietly became a no-op for every image while continuing to report green. A gate
that can be switched off by deleting an unrelated directory is not a gate.

Two changes, both 2026-08-21:

1. **`HEALTHCHECK` restored on every `*-dhi` variant.** Each variant ships a
   `healthcheck.sh` next to its `Dockerfile` (deliberately *not* inside the
   vendored `rootfs/` overlay, which stays byte-identical across variants) and
   copies it to `/opt/bitnami/scripts/healthcheck.sh` — the same path the
   `*-debian13` images used, so anything referencing it keeps working. redis uses
   the original POSIX-sh `redis-cli ping`, unchanged; mongodb uses a `mongosh`
   admin `ping`, which needs no authentication and so works with or without
   `MONGODB_ROOT_PASSWORD`.
2. **The workflow no longer skips silently.** A variant folder containing
   `healthcheck.sh` whose built image declares no `HEALTHCHECK` is now a hard
   `::error::` failure, so the script and the instruction cannot drift apart. An
   image that is genuinely unguarded emits a `::notice::` naming itself, instead
   of skipping without a trace.

Verified 2026-08-21 by building and running every affected image:

| image | declares HEALTHCHECK | reaches healthy | probe exit 0 / 1 |
|-------|---------------------|-----------------|------------------|
| `silta-redis:{7.4,8.4,8.6,8.8,8.10}-dhi` | yes | yes | 0 / 1 |
| `silta-mongodb:8.3-dhi` | yes | yes (~12s) | 0 / 1 |

The gate was also checked for teeth, not just for passing: a redis container left
running while its probe was pointed at a dead port went `unhealthy` after ~53s
(exit 1, 8 consecutive failures), well inside the workflow's 90s wait budget, so
CI would exit 1 and refuse the push. Note that a broken image sits in `starting`
for the first ~15s — Docker does not count failures during `--start-period` — and
the workflow's loop correctly treats `starting` as "keep waiting" rather than as
success. All three branches of the new guard (`error`, `notice`, `proceed`) were
exercised directly against the workflow's own lines.

## silta-mongodb DHI catalog status

Checked 2026-08-20 against `image/mongodb/debian-13` in the same catalog.

| silta variant | DHI | `-compat`? | notes |
|---------------|-----|-----------|-------|
| `6.0-bc` | **absent** | — | no DHI path |
| `7.0-bc` | **absent** | — | no DHI path |
| `8.0-bc`  | 8.0.29 | **no** | plain + `-dev` only |
| `8.2-bc`  | **absent** | — | superseded by 8.3 |
| *(new)* `8.3-dhi` | 8.3.8 | yes | EOL 2029-10-31 |

A DHI migration for mongodb therefore means consolidating onto 8.3 (and possibly
8.0); 6.0 and 7.0 have no DHI path at all.

**`silta-mongodb/8.3-dhi` is not a copy of the redis pattern.** The redis
`-compat` runtime ships `bash coreutils findutils grep mawk openssl procps sed`,
so the Bitnami scripts run unmodified. The mongodb `-compat` runtime ships only
`base-files bash ca-certificates coreutils findutils libcurl4t64 numactl` — no
`sed`, `grep`, `awk` (mawk is explicitly excluded), `hostname` or `getent`, all
of which the vendored scripts need (sed 17 call sites, grep 26, awk 6). It also
needs `yq` at runtime (`libmongodb.sh` `mongodb_conf_get`) and `render-template`
at build time (`postunpack.sh`).

Those seven tools are staged in from a `debian:trixie-slim` builder stage —
trixie is the same Debian release DHI debian13 is built from, so the glibc ABI
matches by construction. Only non-glibc libraries are copied (`libacl`,
`libpcre2-8`, `libselinux`); glibc itself is left untouched in the hardened base.
Staged paths must be canonical `/usr/lib/...`, because both images use merged-usr
(`/lib` is a symlink) and copying a real `/lib` directory over it fails the build.

Other mongodb notes:

- **DHI mongodb is `linux/amd64` only** — redis publishes amd64 + arm64. This
  image cannot be built for arm64.
- The vendored overlay comes from bitnami/containers
  `d4d4ed1856dc04019f0a7e87922dbc4f74916ba8`, path `bitnami/mongodb/8.0/debian-12`
  — the same commit and path the `*-bc` images use, and the newest mongodb tree
  upstream published before the scripts were removed.
- Built and smoke-tested on 2026-08-20: `mongod` 8.3.8 starts and listens on
  27017 as uid 1001, an insert/read round-trip through `mongosh` succeeds, the
  runtime `yq` config path resolves (`yq eval .net.port` → 27017), and all
  mongo-tools (`bsondump`, `mongodump`, …) are present.

### Registry access

`dhi.io` image *pulls* work anonymously — `docker build` and
`docker buildx imagetools inspect` both resolve DHI bases with no credentials.
Only `docker manifest inspect` returns `401 Unauthorized`; that is a quirk of
that subcommand's auth path, not a sign the tag is missing. Use
`docker buildx imagetools inspect` to check a tag by hand, and the catalog repo
above to enumerate tags.

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
