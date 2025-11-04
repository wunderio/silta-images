# https://hub.docker.com/_/rabbitmq/tags
# Use version with management plugin pre-installed (tag ends with -management) due to bitnami chart readiness/liveness probes
FROM rabbitmq:4.2.0-management

# Download Bitnami scripts from specific commit
ARG BITNAMI_CONTAINERS_COMMIT=d4f74c81dd006b07b9a7d8b315d9b3ebe5e351f8
ARG BITNAMI_FILES_PATH=bitnami/rabbitmq/4.1/debian-12

# Set environment variables
ENV BITNAMI_APP_NAME="rabbitmq" \
    BITNAMI_IMAGE_VERSION="4.1.0" \
    RABBITMQ_HOME="/opt/bitnami/rabbitmq" \
    PATH="/opt/bitnami/rabbitmq/sbin:$PATH" \
    RABBITMQ_LOGS="-"

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# UID/GID 1001 required by rabbitmq chart securityContext defaults
USER root
RUN usermod -u 1001 rabbitmq \
    && groupmod -g 1001 rabbitmq \
    && usermod -g 1001 rabbitmq

# Install required packages
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    procps \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Make this image bitnami compatible by creating directories and extra symlinks
# Thanks to https://github.com/ZCube/bitnami-compat/
RUN mkdir -p /opt/bitnami/rabbitmq/{sbin,bin,lib,conf,logs,tmp,var/lib/rabbitmq,var/log/rabbitmq,plugins,.rabbitmq} \
    && mkdir -p /opt/bitnami/rabbitmq/etc/rabbitmq \
    && mkdir -p /opt/bitnami/scripts \
    && mkdir -p /bitnami/rabbitmq/{mnesia,conf,data,logs} \
    && mkdir -p /docker-entrypoint-initdb.d \
    && rm -rf /etc/rabbitmq \
    && ln -sf /opt/bitnami/rabbitmq/etc/rabbitmq /etc/rabbitmq \
    && rm -rf /var/lib/rabbitmq \
    && ln -sf /opt/bitnami/rabbitmq/var/lib/rabbitmq /var/lib/rabbitmq

# Download and extract Bitnami containers repository
RUN curl -sL "https://github.com/bitnami/containers/archive/${BITNAMI_CONTAINERS_COMMIT}.tar.gz" | tar -xz \
    && cp -r "containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/prebuildfs/"* / \
    && cp -r "containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/rootfs/"* / \
    && rm -rf "containers-${BITNAMI_CONTAINERS_COMMIT}"

# Run postunpack script if it exists
RUN /opt/bitnami/scripts/rabbitmq/postunpack.sh

# Set permissions
RUN chown -R 1001:1001 /bitnami \
    && chown -R 1001:1001 /opt/bitnami \
    && chown -R 1001:1001 /var/lib/rabbitmq \
    && chown -R 1001:1001 /var/log/rabbitmq \
    && chmod +x /opt/bitnami/scripts/rabbitmq/*.sh \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && chmod g+rwX /opt/bitnami \
    && find / -perm /6000 -type f -exec chmod a-s {} \; || true

USER 1001
EXPOSE 4369 5671 5672 15672 25672

# Set entrypoint and command
ENTRYPOINT [ "/opt/bitnami/scripts/rabbitmq/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/rabbitmq/run.sh" ]