#!/bin/bash
# Standalone entrypoint for docker run / docker compose.
# In production (Helm), the chart overrides this with its own start scripts.
set -eo pipefail

REDIS_CONF="/opt/bitnami/redis/etc/redis.conf"
REDIS_DEFAULT_CONF="/opt/bitnami/redis/etc/redis-default.conf"

# Copy default config if conf dir is empty (fresh start / emptyDir mount)
if [ ! -f "$REDIS_CONF" ] && [ -f "$REDIS_DEFAULT_CONF" ]; then
    cp "$REDIS_DEFAULT_CONF" "$REDIS_CONF"
fi

# --- Config rendering from env vars ---

# Password
if [ -f "${REDIS_PASSWORD_FILE:-}" ]; then
    REDIS_PASSWORD="$(< "$REDIS_PASSWORD_FILE")"
fi
if [ -n "${REDIS_PASSWORD:-}" ]; then
    sed -i "s/^# *requirepass .*/requirepass ${REDIS_PASSWORD}/" "$REDIS_CONF" 2>/dev/null || true
    sed -i "s/^# *masterauth .*/masterauth ${REDIS_PASSWORD}/" "$REDIS_CONF" 2>/dev/null || true
fi

# AOF persistence
if [ "${REDIS_AOF_ENABLED:-no}" = "yes" ]; then
    sed -i "s/^appendonly .*/appendonly yes/" "$REDIS_CONF" 2>/dev/null || true
fi

# Disable commands
if [ -n "${REDIS_DISABLE_COMMANDS:-}" ]; then
    IFS=',' read -ra CMDS <<< "$REDIS_DISABLE_COMMANDS"
    for cmd in "${CMDS[@]}"; do
        cmd="$(echo "$cmd" | tr -d '[:space:]')"
        echo "rename-command $cmd \"\"" >> "$REDIS_CONF"
    done
fi

# Port
REDIS_PORT="${REDIS_PORT:-6379}"
sed -i "s/^port .*/port ${REDIS_PORT}/" "$REDIS_CONF" 2>/dev/null || true

# --- Launch ---
read -ra extra_flags <<< "${REDIS_EXTRA_FLAGS:-}"
exec redis-server "$REDIS_CONF" --daemonize no "${extra_flags[@]}" "$@"
