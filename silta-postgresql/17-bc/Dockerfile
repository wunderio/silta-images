# https://hub.docker.com/_/postgres/tags
FROM postgres:17.7-bookworm

# Download Bitnami scripts from specific commit
ENV BITNAMI_CONTAINERS_COMMIT=f2675e174c9479e5414428620ae47eefbc1eb213
ENV BITNAMI_FILES_PATH=bitnami/postgresql/17/debian-12

ENV PG_MAJOR=17

# Set environment variables for Bitnami compatibility
ENV BITNAMI_ROOT_DIR="/opt/bitnami" \
    BITNAMI_VOLUME_DIR="/bitnami" \
    BITNAMI_APP_NAME="postgresql" \
    POSTGRESQL_VERSION="17.7" \
    POSTGRESQL_DATA_DIR="/bitnami/postgresql/data" \
    POSTGRESQL_CONF_FILE="/opt/bitnami/postgresql/conf/postgresql.conf" \
    DISABLE_WELCOME_MESSAGE="true" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/postgresql/bin:$PATH"

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# UID/GID 1001 required by postgresql chart securityContext defaults
RUN deluser postgres \
    && groupadd -g 1001 postgres \
    && useradd -u 1001 -g 1001 -d /opt/bitnami/postgresql -s /bin/bash postgres

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Make this image bitnami compatible by creating directories and extra symlinks
# Thanks to https://github.com/ZCube/bitnami-compat/
RUN mkdir -p /opt/bitnami/common/{bin,sbin,lib} \
    && mkdir -p /opt/bitnami/postgresql/{bin,sbin,lib,share,tmp} \
    && mkdir -p /bitnami/postgresql/{data,conf} \
    && ln -sf $(find /usr/lib/*linux-gnu | grep libnss_wrapper.so) /opt/bitnami/common/lib/ \
    && ln -sf /usr/bin/pg_* /opt/bitnami/postgresql/bin/ \
    && ln -sf /usr/lib/postgresql/${PG_MAJOR}/bin/* /opt/bitnami/postgresql/bin/ \
    && ln -sf /usr/lib/postgresql/${PG_MAJOR}/lib/* /opt/bitnami/postgresql/lib/ \
    && ln -sf /usr/sbin/pg_* /opt/bitnami/postgresql/sbin/ \
    && ln -sf /usr/share/postgresql/${PG_MAJOR}/* /opt/bitnami/postgresql/share/

# Install pgaudit extension
RUN apt-get update && apt-get install -y postgresql-${PG_MAJOR}-pgaudit

# Download render-template from official Bitnami repository
RUN mkdir -p /opt/bitnami/common/bin \
    && curl -sL "https://github.com/bitnami/render-template/releases/latest/download/render-template-linux-amd64.tar.gz" \
    | tar -xz -C /tmp \
    && mv /tmp/render-template-linux-amd64 /opt/bitnami/common/bin/render-template \
    && chmod +x /opt/bitnami/common/bin/render-template

# Download and extract Bitnami containers repository
RUN curl -sL "https://github.com/bitnami/containers/archive/${BITNAMI_CONTAINERS_COMMIT}.tar.gz" \
    | tar -xz -C /tmp \
    && cp -r /tmp/containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/prebuildfs/* / \
    && cp -r /tmp/containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/rootfs/* / \
    && rm -rf /tmp/containers-${BITNAMI_CONTAINERS_COMMIT}

# Fix PostgreSQL 16 compatibility issues in Bitnami scripts
# psql --version returns "psql (PostgreSQL) 16.1 (Debian 16.1-1.pgdg110+1)" which breaks the Bitnami scripts
# Maybe a local fork is required
RUN sed -i '/psql --version/ s/$/ | head -n 1/' /opt/bitnami/scripts/libpostgresql.sh

# Run postunpack script to generate default configuration
RUN /opt/bitnami/scripts/postgresql/postunpack.sh

# Fix permissions after postunpack script creates configuration files
# Set permissions
RUN chown 1001:1001 -R /var/run/postgresql /var/lib/postgresql /var/log/postgresql /opt/bitnami/postgresql /bitnami/postgresql

USER 1001
WORKDIR /opt/bitnami/postgresql
EXPOSE 5432

# Use Bitnami entrypoint
ENTRYPOINT ["/opt/bitnami/scripts/postgresql/entrypoint.sh"]
CMD ["/opt/bitnami/scripts/postgresql/run.sh"]
