# DHI hardened Redis 8.0 — Bitnami-free.
# Replaces Bitnami's ~2000 lines of shell libraries with minimal stubs (~120 lines).
# Compatible with Bitnami Redis Helm chart (19.x) in all modes: standalone, replication, sentinel.
# The chart overrides ENTRYPOINT/CMD via ConfigMap start scripts — the entrypoint here is
# only used for standalone docker run / docker compose.
FROM dhi.io/redis:8.0-debian13-dev

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# UID/GID 1001 required by redis chart securityContext defaults (runAsUser: 1001, fsGroup: 1001)
RUN grep -q '^redis:' /etc/passwd || echo 'redis:x:1001:1001:redis:/data:/bin/bash' >> /etc/passwd \
    && grep -q '^redis:' /etc/group || echo 'redis:x:1001:redis' >> /etc/group

# Install only runtime packages needed by the chart's health/start scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gzip \
    openssl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# --- Directory contract ---
# These paths are hardcoded in the Helm chart templates (volume mounts, ConfigMap mounts, scripts).
RUN mkdir -p \
    /bitnami/redis/{conf,data,logs} \
    /opt/bitnami/redis/{bin,etc,etc.default,mounted-etc,secrets,certs,logs,tmp,conf} \
    /opt/bitnami/redis-sentinel/etc \
    /opt/bitnami/scripts/start-scripts \
    /health \
    /data \
    /tmp

# Symlink redis binaries to the path the chart expects
# DHI 8.0 base installs redis at /usr/bin/ (not /usr/local/bin/)
RUN REDIS_BIN=$(dirname "$(command -v redis-server)") \
    && ln -sf "$REDIS_BIN/redis-server" /opt/bitnami/redis/bin/redis-server \
    && ln -sf "$REDIS_BIN/redis-cli" /opt/bitnami/redis/bin/redis-cli \
    && ln -sf "$REDIS_BIN/redis-sentinel" /opt/bitnami/redis/bin/redis-sentinel \
    && ln -sf "$REDIS_BIN/redis-check-aof" /opt/bitnami/redis/bin/redis-check-aof \
    && ln -sf "$REDIS_BIN/redis-check-rdb" /opt/bitnami/redis/bin/redis-check-rdb \
    && ln -sf "$REDIS_BIN/redis-benchmark" /opt/bitnami/redis/bin/redis-benchmark

# --- Minimal library stubs ---
COPY scripts/liblog.sh         /opt/bitnami/scripts/liblog.sh
COPY scripts/libos.sh          /opt/bitnami/scripts/libos.sh
COPY scripts/libvalidations.sh /opt/bitnami/scripts/libvalidations.sh
COPY scripts/libfile.sh        /opt/bitnami/scripts/libfile.sh
COPY scripts/libfs.sh          /opt/bitnami/scripts/libfs.sh
COPY scripts/libbitnami.sh     /opt/bitnami/scripts/libbitnami.sh

# --- Default Redis config ---
COPY redis-default.conf /opt/bitnami/redis/etc/redis-default.conf
RUN cp /opt/bitnami/redis/etc/redis-default.conf /opt/bitnami/redis/etc/redis.conf \
    && sed -i 's/^port .*/port 6379/' /opt/bitnami/redis/etc/redis.conf \
    && sed -i 's|^dir .*|dir /data|' /opt/bitnami/redis/etc/redis.conf \
    && sed -i 's/^daemonize .*/daemonize no/' /opt/bitnami/redis/etc/redis.conf \
    && sed -i 's/^logfile .*/logfile ""/' /opt/bitnami/redis/etc/redis.conf \
    && cp -r /opt/bitnami/redis/etc/* /opt/bitnami/redis/etc.default/

# --- Standalone entrypoint ---
COPY scripts/entrypoint.sh /opt/bitnami/scripts/entrypoint.sh

# Convenience symlinks
RUN ln -sf /opt/bitnami/scripts/entrypoint.sh /entrypoint.sh

# --- Permissions ---
RUN chown -R 1001:1001 /bitnami /opt/bitnami /data \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && chmod g+rwX /opt/bitnami \
    && find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Environment variables consumed by chart scripts and health checks
ENV PATH="/opt/bitnami/redis/bin:$PATH" \
    REDIS_PORT="6379" \
    REDIS_DATA_DIR="/data" \
    BITNAMI_DEBUG="false"

USER 1001
EXPOSE 6379

ENTRYPOINT [ "/opt/bitnami/scripts/entrypoint.sh" ]
CMD []
