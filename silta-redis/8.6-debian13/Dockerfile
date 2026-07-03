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

FROM dhi.io/redis:8.6-debian13

# Copy only prepared runtime artifacts from builder.
COPY --from=builder /bitnami /bitnami
COPY --from=builder /opt/bitnami /opt/bitnami
COPY --from=builder /data /data
COPY --from=builder /entrypoint.sh /entrypoint.sh

# Ensure chart-required users are present in runtime image.
RUN set -eux; \
    if ! grep -q '^redis:' /etc/passwd; then \
      echo 'redis:x:1001:1001:redis:/data:/bin/bash' >> /etc/passwd; \
    fi; \
    if ! grep -q '^redis:' /etc/group; then \
      echo 'redis:x:1001:redis' >> /etc/group; \
    fi

# Ensure required runtime tools exist. Install minimal fallback packages only if needed.
RUN set -eux; \
    missing=""; \
    for tool in bash timeout openssl sed awk getent redis-server redis-cli; do \
      command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"; \
    done; \
    if [ -n "$missing" ]; then \
      echo "Installing missing runtime tools:$missing"; \
      if command -v apt-get >/dev/null 2>&1; then \
        apt-get update; \
        apt-get install -y --no-install-recommends \
          bash \
          coreutils \
          openssl \
          sed \
          gawk \
          libc-bin \
          ca-certificates \
          procps; \
        rm -rf /var/lib/apt/lists/*; \
      else \
        echo "Runtime base has no apt-get and is missing required tools:$missing"; \
        exit 1; \
      fi; \
    fi; \
    command -v bash; \
    command -v timeout; \
    command -v openssl; \
    command -v sed; \
    command -v awk; \
    command -v getent; \
    command -v redis-server; \
    command -v redis-cli

# Keep runtime permissions/security contract aligned with other variants.
RUN chown -R 1001:1001 /bitnami /opt/bitnami /data \
    && chmod +x /opt/bitnami/scripts/*.sh \
    && chmod g+rwX /opt/bitnami \
    && find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Environment variables consumed by chart scripts
ENV PATH="/opt/bitnami/redis/bin:$PATH" \
    REDIS_PORT="6379" \
    REDIS_DATA_DIR="/data" \
    BITNAMI_DEBUG="false"

USER 1001
EXPOSE 6379

ENTRYPOINT [ "/opt/bitnami/scripts/entrypoint.sh" ]
CMD []
