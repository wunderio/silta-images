# https://hub.docker.com/_/memcached/tags
FROM memcached:1.6.39

# Bitnami commit hash for rootfs downloads
ARG BITNAMI_CONTAINERS_COMMIT=95fea787a9e62e4b16c4bdf2be16c535d5c6f544
ARG BITNAMI_FILES_PATH=bitnami/memcached/1/debian-12

ENV BITNAMI_APP_NAME="memcached" \
    BITNAMI_IMAGE_VERSION="1.6.8" \
    PATH="/opt/bitnami/memcached/bin:$PATH"

# UID/GID 1001 required by memcached chart securityContext defaults
USER root
RUN usermod -u 1001 memcache && \
    groupmod -g 1001 memcache && \
    ln -sf /home/memcache /home/bitnami

# Use archived repositories for Debian Buster (10) because 1.6.8 base image is based on it.
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list \
    && sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list \
    && sed -i '/buster-updates/d' /etc/apt/sources.list \
    && apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Bitnami compatible directory structure
# Based on paths in https://github.com/bitnami/containers
RUN mkdir -p /opt/bitnami/memcached/{bin,sbin,lib,conf,logs,tmp} \
    && mkdir -p /bitnami/memcached/{conf,logs} \
    && ln -s /opt/bitnami/scripts/memcached/run.sh /run.sh \
    && rm /entrypoint.sh \
    && ln -s /opt/bitnami/scripts/memcached/entrypoint.sh /entrypoint.sh \
    && chown -R 1001:1001 /bitnami \
    && chown -R 1001:1001 /opt/bitnami

# Download Bitnami scripts from GitHub
RUN curl -L "https://github.com/bitnami/containers/archive/${BITNAMI_CONTAINERS_COMMIT}.tar.gz" | tar -xz -C /tmp \
    && mkdir -p /opt/bitnami/scripts \
    && cp -r "/tmp/containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/prebuildfs/"* / \
    && cp -r "/tmp/containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/rootfs/"* / \
    && chmod +x /opt/bitnami/scripts/memcached/*.sh \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && rm -rf /tmp/containers-${BITNAMI_CONTAINERS_COMMIT}

RUN /opt/bitnami/scripts/memcached/postunpack.sh

USER 1001
WORKDIR /opt/bitnami/memcached
EXPOSE 11211

ENTRYPOINT ["/opt/bitnami/scripts/memcached/entrypoint.sh"]
CMD ["/opt/bitnami/scripts/memcached/run.sh"]
