# https://hub.docker.com/_/mariadb/tags
FROM mariadb:12.0.2

# Bitnami commit for script downloads
ARG BITNAMI_CONTAINERS_COMMIT=0ef447b0dcac9d5ed1142d4900b555a694ec3ddb
ARG BITNAMI_FILES_PATH=bitnami/mariadb/10.6/debian-12

# Set environment variables
ENV APP_VERSION="10.6.23" \
    BITNAMI_APP_NAME="mariadb" \
    PATH="/usr/sbin:/usr/bin:/opt/bitnami/common/bin:/opt/bitnami/common/sbin:/opt/bitnami/mariadb/bin:/opt/bitnami/mariadb/sbin:$PATH"

# Change existing mysql user/group to 1001 (required by Bitnami Helm chart)
RUN usermod -u 1001 mysql && groupmod -g 1001 mysql

# Make this image bitnami compatible by creating symlinks
# Thanks to https://github.com/ZCube/bitnami-compat/
RUN mkdir -p /opt/bitnami/mariadb/bin \
    && mkdir -p /opt/bitnami/mariadb/sbin \
    && mkdir -p /opt/bitnami/mariadb/lib \
    && mkdir -p /opt/bitnami/mariadb/conf \
    && ln -s /usr/bin/aria_chk                     /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/aria_dump_log                /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/aria_ftdump                  /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/aria_pack                    /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/aria_read_log                /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/innochecksum                 /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/mbstream                     /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/msql2mysql                   /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/perror                       /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/replace                      /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/resolve_stack_dump           /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/resolveip                    /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/sst_dump                     /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/wsrep_sst_common             /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/wsrep_sst_mariabackup        /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/wsrep_sst_mysqldump          /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/wsrep_sst_rsync              /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/wsrep_sst_rsync_wan          /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/bin/my*                          /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/sbin/my*                         /opt/bitnami/mariadb/sbin/ \
    && ln -s /usr/bin/maria*                       /opt/bitnami/mariadb/bin/ \
    && ln -s /usr/sbin/maria*                      /opt/bitnami/mariadb/sbin/ \
    && cp -rf /usr/lib/mysql/plugin/               /opt/bitnami/mariadb/plugin/ \
    && cp -rf /usr/share/mysql/                    /opt/bitnami/mariadb/share/ \
    && rm -rf /var/lib/dpkg/alternatives/my.cnf \
    && rm -rf /etc/mysql/my.cnf \
    && rm -rf /etc/mysql/mariadb.cnf \
    && touch /opt/bitnami/mariadb/conf/my.cnf \
    && rm -rf /etc/mysql/* \
    && chown -R root:root /usr/lib/mysql/plugin/auth_pam_tool_dir/ \
    && chmod -R 755 /usr/lib/mysql/plugin/auth_pam_tool_dir/ \
    && ln -sf /opt/bitnami/mariadb/conf/my.cnf /etc/mysql/my.cnf \
    && ln -sf /opt/bitnami/mariadb/conf/bitnami /etc/mysql/bitnami \
    && rm -f /opt/bitnami/mariadb/conf/my.cnf

# Install required packages
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    libaio1 \
    libaudit1 \
    libcap-ng0 \
    libcrypt1 \
    libgcc-s1 \
    liblzma5 \
    libncurses6 \
    libpam0g \
    libstdc++6 \
    libtinfo6 \
    libxml2 \
    procps \
    psmisc \
    zlib1g \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download Bitnami scripts from GitHub
RUN curl -L "https://github.com/bitnami/containers/archive/${BITNAMI_CONTAINERS_COMMIT}.tar.gz" | tar -xz -C /tmp \
    && mkdir -p /opt/bitnami/scripts \
    && cp -r "/tmp/containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/prebuildfs/"* / \
    && cp -r "/tmp/containers-${BITNAMI_CONTAINERS_COMMIT}/${BITNAMI_FILES_PATH}/rootfs/"* / \
    && chmod +x /opt/bitnami/scripts/mariadb/*.sh \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && rm -rf /tmp/containers-${BITNAMI_CONTAINERS_COMMIT}

# Create required directories and set proper permissions
RUN mkdir -p /bitnami/mariadb/data \
    && mkdir -p /bitnami/mariadb/logs \
    && mkdir -p /opt/bitnami/mariadb/logs \
    && mkdir -p /opt/bitnami/mariadb/tmp \
    && mkdir -p /opt/bitnami/mariadb/data \
    && chown -R 1001:1001 /bitnami \
    && chown -R 1001:1001 /opt/bitnami \
    && chmod g+rwX /opt/bitnami \
    && find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Run postunpack script
RUN /opt/bitnami/scripts/mariadb/postunpack.sh

USER 1001
EXPOSE 3306

# Set entrypoint and command
ENTRYPOINT [ "/opt/bitnami/scripts/mariadb/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/mariadb/run.sh" ]