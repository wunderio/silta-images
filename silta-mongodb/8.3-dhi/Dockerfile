# Proof of concept: Bitnami-compatible mongodb on a Docker Hardened Images base
# https://hub.docker.com/hardened-images/catalog/dhi/mongodb
# Pulling from dhi.io requires a (free) Docker account: docker login dhi.io
#
# The Bitnami script overlay in rootfs/ is vendored from
# https://github.com/bitnami/containers at commit
# d4d4ed1856dc04019f0a7e87922dbc4f74916ba8, path bitnami/mongodb/8.0/debian-12
# (prebuildfs + rootfs merged, apt wrapper scripts dropped) — the same commit
# and path the silta-mongodb *-bc images build from. 8.0 is the newest mongodb
# tree upstream published before the scripts were removed, so this local copy
# is the source of truth.
#
# IMPORTANT — this differs from silta-redis/*-dhi in one significant way.
# The redis -compat flavor ships bash/coreutils/sed/grep/mawk/procps, so the
# Bitnami scripts run as-is. The mongodb -compat flavor ships only:
#   base-files bash ca-certificates coreutils findutils libcurl4t64 numactl
# It has no sed, grep, awk, hostname or getent (and mawk is explicitly
# excluded), yet the vendored scripts need all of them:
#   sed      17 call sites (mongodb_conf_set / journal + config rewriting)
#   grep     26 call sites (config checks, replica-set init result parsing)
#   awk       6 call sites (libnet.sh dns_lookup)
#   hostname  libnet.sh:64
#   getent    libos.sh:37, libnet.sh:26
#   yq        libmongodb.sh:641 (mongodb_conf_get) — runtime
# plus render-template, needed at build time by mongodb/postunpack.sh.
#
# DHI has no package manager and no curl, so those are staged in from a
# debian:trixie-slim builder. trixie is the same Debian release DHI debian13 is
# built from, so the glibc ABI matches by construction. Only non-glibc
# libraries are copied — glibc itself is already present in the base and must
# not be overwritten.

# ---------------------------------------------------------------------------
# Stage 1: assemble the tools the -compat runtime is missing
# ---------------------------------------------------------------------------
FROM debian:trixie-slim AS toolchain

ARG YQ_VERSION=v4.53.6
ARG RENDER_TEMPLATE_VERSION=v1.0.10
ARG TOOL_ARCH=amd64

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl sed grep mawk hostname libc-bin \
    && rm -rf /var/lib/apt/lists/*

# yq and render-template are statically linked Go binaries — no library deps.
RUN curl -fsSL -o /tmp/yq \
        "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TOOL_ARCH}" \
    && curl -fsSL "https://github.com/bitnami/render-template/releases/download/${RENDER_TEMPLATE_VERSION}/render-template-linux-${TOOL_ARCH}.tar.gz" \
        | tar -xz -C /tmp \
    && mv "/tmp/render-template-linux-${TOOL_ARCH}" /tmp/render-template \
    && chmod +x /tmp/yq /tmp/render-template

# Collect the GNU tools plus any non-glibc shared libraries they pull in.
# glibc (libc/ld-linux/libm/libdl/libpthread/librt) is deliberately skipped:
# the DHI base already provides it and overwriting a hardened base's libc is
# both unnecessary and undesirable.
# Staged paths must be canonical: Debian (and the DHI base) use merged-usr, so
# /lib is a symlink to usr/lib. Staging a real /lib directory makes the final
# COPY fail with "cannot copy to non-directory: /lib". `pwd -P` resolves the
# directory, and `cp -L` dereferences versioned symlinks while keeping the
# soname filename the dynamic linker actually looks for.
RUN set -eux; \
    mkdir -p /sysroot/usr/bin /sysroot/usr/local/bin; \
    stage() { \
        d="$(cd "$(dirname "$1")" && pwd -P)"; \
        mkdir -p "/sysroot$d"; \
        cp -L "$1" "/sysroot$d/$(basename "$1")"; \
    }; \
    for bin in /usr/bin/sed /usr/bin/grep /usr/bin/mawk /usr/bin/hostname /usr/bin/getent; do \
        test -x "$bin"; \
        stage "$bin"; \
        ldd "$bin" | mawk '/=>/ && $3 ~ /^\// { print $3 }' | while read -r lib; do \
            case "$(basename "$lib")" in \
                libc.so.*|ld-linux*|libm.so.*|libdl.so.*|libpthread.so.*|librt.so.*) continue ;; \
            esac; \
            stage "$lib"; \
        done; \
    done; \
    ln -sf mawk /sysroot/usr/bin/awk; \
    cp /tmp/yq /sysroot/usr/local/bin/yq; \
    cp /tmp/render-template /sysroot/usr/local/bin/render-template; \
    echo "--- staged into /sysroot:"; find /sysroot -type f -o -type l | sort

# ---------------------------------------------------------------------------
# Stage 2: the Bitnami-compatible mongodb image
# ---------------------------------------------------------------------------
# https://hub.docker.com/hardened-images/catalog/dhi/mongodb/tags
# NOTE: DHI mongodb publishes linux/amd64 only (redis publishes amd64+arm64),
# so this image cannot be built for arm64.
FROM dhi.io/mongodb:8.3-compat

ENV BITNAMI_APP_NAME="mongodb" \
    BITNAMI_IMAGE_VERSION="8.3.8" \
    BITNAMI_ROOT_DIR="/opt/bitnami" \
    BITNAMI_VOLUME_DIR="/bitnami" \
    MONGODB_DATA_DIR="/bitnami/mongodb/data" \
    MONGODB_CONF_FILE="/opt/bitnami/mongodb/conf/mongodb.conf" \
    DISABLE_WELCOME_MESSAGE="true" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/mongodb/bin:/usr/local/bin:$PATH"

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# DHI runs as nonroot (mongodb, uid 999) by default, build steps need root
USER 0

# UID/GID 1001 required by mongodb chart securityContext defaults, and the
# scripts run the daemon as MONGODB_DAEMON_USER=mongo. DHI ships no
# shadow-utils (useradd/groupadd), so append the entries directly.
RUN echo 'mongo:x:1001:1001:mongo:/opt/bitnami/mongodb:/usr/sbin/nologin' >> /etc/passwd \
    && echo 'mongo:x:1001:' >> /etc/group

# Tools the -compat runtime does not ship (see header)
COPY --from=toolchain /sysroot/ /

# Vendored Bitnami script overlay
COPY rootfs/ /

COPY healthcheck.sh /opt/bitnami/scripts/healthcheck.sh

# Make this image bitnami compatible by creating directories and extra symlinks
# Thanks to https://github.com/ZCube/bitnami-compat/
# DHI lays the binaries out as: mongod -> /usr/bin/mongod,
# mongosh -> /usr/bin/mongosh, mongo-tools -> /usr/local/bin/.
RUN mkdir -p /opt/bitnami/scripts \
    && mkdir -p /opt/bitnami/common/bin \
    && mkdir -p /opt/bitnami/mongodb/{bin,sbin,lib,conf,logs,tmp,conf.default,templates} \
    && mkdir -p /bitnami/mongodb/{conf,data,logs} \
    && mkdir -p /bitnami/mongodb/data/db \
    && ln -s /usr/bin/mongod /opt/bitnami/mongodb/bin/mongod \
    && ln -s /usr/bin/mongosh /opt/bitnami/mongodb/bin/mongosh \
    && for tool in bsondump mongodump mongoexport mongofiles mongoimport mongorestore mongostat mongotop; do \
           if [ -x "/usr/local/bin/$tool" ]; then ln -s "/usr/local/bin/$tool" "/opt/bitnami/mongodb/bin/$tool"; fi; \
       done \
    && ln -s /usr/local/bin/render-template /opt/bitnami/common/bin/render-template \
    && ln -s /opt/bitnami/scripts/mongodb/run.sh /run.sh \
    && ln -s /opt/bitnami/scripts/mongodb/entrypoint.sh /entrypoint.sh

RUN /opt/bitnami/scripts/mongodb/postunpack.sh

# Copy configuration files and set permissions
RUN chown -R 1001:1001 /bitnami \
    && chown -R 1001:1001 /opt/bitnami \
    && chown -R 1001:1001 /data \
    && chmod +x /opt/bitnami/scripts/mongodb/*.sh \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && chmod g+rwX /opt/bitnami

USER 1001
EXPOSE 27017

# Functional gate for docker run / compose and the CI wait-for-healthy step in
# .github/workflows/docker-images.yml. Kubernetes ignores docker HEALTHCHECK;
# the Helm chart uses its own probes. mongosh takes longer to connect than
# redis-cli, hence the wider start-period/timeout than the redis variants.
HEALTHCHECK --interval=10s --timeout=10s --start-period=30s --retries=6 \
    CMD /opt/bitnami/scripts/healthcheck.sh

# Set entrypoint
ENTRYPOINT [ "/opt/bitnami/scripts/mongodb/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/mongodb/run.sh" ]