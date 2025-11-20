# https://hub.docker.com/_/mongo/tags
FROM mongo:8.2.2

# Download Bitnami scripts from specific commit
ARG BITNAMI_CONTAINERS_COMMIT=2dcd36f2b49a0164185544729a3b88babe380521
ARG BITNAMI_FILES_PATH=bitnami/mongodb/6.0/debian-11

# Set up environment variables
ENV BITNAMI_APP_NAME="mongodb" \
    BITNAMI_IMAGE_VERSION="6.0.13" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/mongodb/bin:$PATH" \
    BITNAMI_ROOT_DIR="/opt/bitnami" \
    BITNAMI_VOLUME_DIR="/bitnami" \
    MONGODB_DATA_DIR="/bitnami/mongodb/data" \
    MONGODB_CONF_FILE="/opt/bitnami/mongodb/conf/mongodb.conf"

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# UID/GID 1001 required by mongodb chart securityContext defaults
RUN groupadd -g 1001 mongo || true \
    && useradd -u 1001 -g 1001 -s /bin/bash mongo || true

# Install required packages
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Make this image bitnami compatible by creating directories and extra symlinks
# Thanks to https://github.com/ZCube/bitnami-compat/
RUN mkdir -p /opt/bitnami/scripts \
    && mkdir -p /opt/bitnami/mongodb/{bin,sbin,lib,conf,logs,tmp,conf.default,templates} \
    && mkdir -p /bitnami/mongodb/{conf,data,logs} \
    && mkdir -p /bitnami/mongodb/data/db \
    && ln -s /usr/bin/bsondump /opt/bitnami/mongodb/bin/ \
    && ln -s /usr/bin/mongo* /opt/bitnami/mongodb/bin/ \
    && ln -s /opt/bitnami/scripts/mongodb/run.sh /run.sh \
    && ln -s /opt/bitnami/scripts/mongodb/entrypoint.sh /entrypoint.sh

# Download render-template from official Bitnami repository
RUN mkdir -p /opt/bitnami/common/bin \
    && curl -sL "https://github.com/bitnami/render-template/releases/latest/download/render-template-linux-amd64.tar.gz" \
    | tar -xz -C /tmp \
    && mv /tmp/render-template-linux-amd64 /opt/bitnami/common/bin/render-template \
    && chmod +x /opt/bitnami/common/bin/render-template

# Download and extract Bitnami containers repository
RUN curl -sL "https://github.com/bitnami/containers/archive/${BITNAMI_CONTAINERS_COMMIT}.tar.gz" | tar -xz \
    && cp -r "containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/prebuildfs/"* / \
    && cp -r "containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/rootfs/"* / \
    && rm -rf "containers-${BITNAMI_CONTAINERS_COMMIT}"

RUN /opt/bitnami/scripts/mongodb/postunpack.sh

# Set permissions
RUN chown -R 1001:1001 /bitnami \
    && chown -R 1001:1001 /opt/bitnami \
    && chmod +x /opt/bitnami/scripts/mongodb/*.sh \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && chmod g+rwX /opt/bitnami \
    && find / -perm /6000 -type f -exec chmod a-s {} \; || true

USER 1001
EXPOSE 27017

# Set entrypoint
ENTRYPOINT [ "/opt/bitnami/scripts/mongodb/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/mongodb/run.sh" ]
