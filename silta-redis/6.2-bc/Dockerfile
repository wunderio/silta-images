# https://hub.docker.com/_/redis/tags
FROM redis:8.2.3

# Download Bitnami scripts from specific commit
ARG BITNAMI_CONTAINERS_COMMIT=c82049f82665c8acc980d2fafadac2542a2a73fa
ARG BITNAMI_FILES_PATH=bitnami/redis/6.2/debian-12

ENV BITNAMI_APP_NAME="redis" \
    BITNAMI_IMAGE_VERSION="6.2.7" \
    PATH="/opt/bitnami/redis/bin:$PATH"

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# UID/GID 1001 required by redis chart securityContext defaults
RUN usermod -u 1001 redis \
    && groupmod -g 1001 redis \
    && usermod -g 1001 redis

# Install required packages
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Make this image bitnami compatible by creating directories and extra symlinks
# Thanks to https://github.com/ZCube/bitnami-compat/
RUN mkdir -p /bitnami/redis/{conf,data,logs} \
    && mkdir -p /opt/bitnami/redis/{bin,sbin,lib,etc,logs,tmp,conf,etc.default} \
    && mkdir -p /opt/bitnami/scripts \
    && ln -s /opt/bitnami/scripts/redis/run.sh /run.sh \
    && ln -s /opt/bitnami/scripts/redis/entrypoint.sh /entrypoint.sh \
    && ln -s /usr/local/bin/redis* /opt/bitnami/redis/bin/

# Download and extract Bitnami containers repository
RUN curl -sL "https://github.com/bitnami/containers/archive/${BITNAMI_CONTAINERS_COMMIT}.tar.gz" | tar -xz \
    && cp -r "containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/prebuildfs/"* / \
    && cp -r "containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/rootfs/"* / \
    && rm -rf "containers-${BITNAMI_CONTAINERS_COMMIT}"

# https://downloads.bitnami.com/files/stacksmith/redis-6.2.16-1-linux-amd64-debian-12.tar.gz
COPY redis-default.conf /opt/bitnami/redis/etc/redis-default.conf

RUN /opt/bitnami/scripts/redis/postunpack.sh

# Copy configuration files and set permissions
RUN chown -R 1001:1001 /bitnami \
    && chown -R 1001:1001 /opt/bitnami \
    && chmod +x /opt/bitnami/scripts/redis/*.sh \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && chmod g+rwX /opt/bitnami \
    && find / -perm /6000 -type f -exec chmod a-s {} \; || true

USER 1001
EXPOSE 6379

# Set entrypoint
ENTRYPOINT [ "/opt/bitnami/scripts/redis/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/redis/run.sh" ]
