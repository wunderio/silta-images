# DHI hardened Redis 8.6 — Bitnami-free.
# Replaces Bitnami's ~2000 lines of shell libraries with minimal stubs (~120 lines).
# Compatible with Bitnami Redis Helm chart (19.x) in all modes: standalone, replication, sentinel.
# The chart overrides ENTRYPOINT/CMD via ConfigMap start scripts — the entrypoint here is
# only used for standalone docker run / docker compose.
#
# Multi-stage spike:
# - builder stage uses -dev to prepare chart-compat filesystem and scripts
# - runtime stage uses non-dev base to reduce final image surface

FROM dhi.io/redis:8.6-debian13-dev AS builder

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
# Auto-detect binary location — DHI bases may use /usr/local/bin or /usr/bin
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
    && chmod g+rwX /opt/bitnami

# --- Prepare runtime toolset for chart start scripts ---
# Non-dev runtime is stripped; stage required CLI tools and their shared libs.
RUN set -eux; \
    mkdir -p /tool-root; \
    tools="bash cp mv rm mkdir chmod chown ln cat sed awk grep cut tr env printenv timeout getent openssl"; \
    for tool in $tools; do \
      bin="$(command -v "$tool")"; \
      bin_dst="/tool-root$bin"; \
      mkdir -p "$(dirname "$bin_dst")"; \
      cp -a "$bin" "$bin_dst"; \
      ldd "$bin" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^\//) print $i}' | while read -r lib; do \
        lib_dst="/tool-root$lib"; \
        mkdir -p "$(dirname "$lib_dst")"; \
        cp -a "$lib" "$lib_dst"; \
      done; \
    done; \
    if [ -e /lib64/ld-linux-x86-64.so.2 ]; then \
      mkdir -p /tool-root/lib64; \
      cp -a /lib64/ld-linux-x86-64.so.2 /tool-root/lib64/; \
    fi

FROM dhi.io/redis:8.6-debian13

# Copy required runtime toolset from builder.
COPY --from=builder /tool-root/ /

# Copy only prepared runtime artifacts from builder.
COPY --from=builder /bitnami /bitnami
COPY --from=builder /opt/bitnami /opt/bitnami
COPY --from=builder /data /data
COPY --from=builder /entrypoint.sh /entrypoint.sh
# Runtime base is stripped, but bash + libs now available from builder.
# Copy passwd/group from builder to keep redis:1001 identity contract.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Environment variables consumed by chart scripts
ENV PATH="/opt/bitnami/redis/bin:$PATH" \
    REDIS_PORT="6379" \
    REDIS_DATA_DIR="/data" \
    BITNAMI_DEBUG="false"

USER 1001
EXPOSE 6379

ENTRYPOINT [ "/opt/bitnami/scripts/entrypoint.sh" ]
CMD []
