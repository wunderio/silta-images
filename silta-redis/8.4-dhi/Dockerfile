# Proof of concept: Bitnami-compatible redis on a Docker Hardened Images base
# https://hub.docker.com/hardened-images/catalog/dhi/redis
# The -compat flavor ships bash/coreutils/sed/grep/procps, which the Bitnami
# scripts need at runtime. DHI has no package manager or curl.
# Pulling from dhi.io requires a (free) Docker account: docker login dhi.io
#
# The Bitnami script overlay in rootfs/ is vendored from
# https://github.com/bitnami/containers at commit
# 903afb7338c707fe34a6987ac5b5ea4c2e18ec42, path bitnami/redis/8.4/debian-12
# (prebuildfs + rootfs merged, apt wrapper scripts dropped). The scripts are
# distro-agnostic; upstream has since removed them from the current tree, so
# this local copy is the source of truth.

# https://hub.docker.com/hardened-images/catalog/dhi/redis/tags
FROM dhi.io/redis:8.4.4-compat

ENV BITNAMI_APP_NAME="redis" \
    BITNAMI_IMAGE_VERSION="8.4.4" \
    DISABLE_WELCOME_MESSAGE="true" \
    PATH="/opt/bitnami/redis/bin:$PATH"

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# DHI runs as nonroot (65532) by default, build steps need root
USER 0

# UID/GID 1001 required by redis chart securityContext defaults.
# DHI ships no shadow-utils (useradd/usermod), so append the entries directly.
RUN echo 'redis:x:1001:1001:redis:/opt/bitnami/redis:/usr/sbin/nologin' >> /etc/passwd \
    && echo 'redis:x:1001:' >> /etc/group

# Vendored Bitnami script overlay
COPY rootfs/ /

# Make this image bitnami compatible by creating directories and extra symlinks
# Thanks to https://github.com/ZCube/bitnami-compat/
RUN mkdir -p /bitnami/redis/{conf,data,logs} \
    && mkdir -p /opt/bitnami/redis/{bin,sbin,lib,etc,logs,tmp,conf,etc.default} \
    && ln -s /opt/bitnami/scripts/redis/run.sh /run.sh \
    && ln -s /opt/bitnami/scripts/redis/entrypoint.sh /entrypoint.sh \
    && ln -s /usr/local/bin/redis* /opt/bitnami/redis/bin/

COPY redis-default.conf /opt/bitnami/redis/etc/redis-default.conf

RUN /opt/bitnami/scripts/redis/postunpack.sh

# Copy configuration files and set permissions
RUN chown -R 1001:1001 /bitnami \
    && chown -R 1001:1001 /opt/bitnami \
    && chmod +x /opt/bitnami/scripts/redis/*.sh \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && chmod g+rwX /opt/bitnami

USER 1001
EXPOSE 6379

# Set entrypoint
ENTRYPOINT [ "/opt/bitnami/scripts/redis/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/redis/run.sh" ]
