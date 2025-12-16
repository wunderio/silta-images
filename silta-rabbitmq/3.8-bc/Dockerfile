# https://hub.docker.com/_/rabbitmq/tags
# Use version with management plugin pre-installed (tag ends with -management) due to bitnami chart readiness/liveness probes
FROM rabbitmq:3.8.2-management

# Download Bitnami scripts from specific commit
ARG BITNAMI_CONTAINERS_COMMIT=794c0d83cf265d1daf5029de7ce627c84dd65b8c
ARG BITNAMI_FILES_PATH=bitnami/rabbitmq/3.8/debian-11

# Set environment variables
ENV BITNAMI_APP_NAME="rabbitmq" \
    BITNAMI_IMAGE_VERSION="3.8.2" \
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
RUN mkdir -p /opt/bitnami \
    && ln -sf /opt/rabbitmq /opt/bitnami/rabbitmq

# Download and extract Bitnami containers repository
RUN curl -sL "https://github.com/bitnami/containers/archive/${BITNAMI_CONTAINERS_COMMIT}.tar.gz" | tar -xz \
    && cp -r "containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/prebuildfs/"* / \
    && cp -r "containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/rootfs/"* / \
    && rm -rf "containers-${BITNAMI_CONTAINERS_COMMIT}"

# Run postunpack script
RUN /opt/bitnami/scripts/rabbitmq/postunpack.sh

# Set permissions
RUN chown -R 1001:1001 /bitnami/rabbitmq \
    && chown -R 1001:1001 /var/lib/rabbitmq

USER 1001
EXPOSE 4369 5671 5672 15672 25672

# Set entrypoint and command
ENTRYPOINT [ "/opt/bitnami/scripts/rabbitmq/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/rabbitmq/run.sh" ]