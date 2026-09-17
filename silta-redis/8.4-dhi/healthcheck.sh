#!/bin/sh
# Standalone container healthcheck: verify redis-server responds to PING.
# Used by docker run / docker compose and by CI wait-for-healthy.
# Kubernetes ignores docker HEALTHCHECK; the Helm chart uses its own probes.
pass="${REDIS_PASSWORD:-}"
[ -f "${REDIS_PASSWORD_FILE:-}" ] && pass="$(cat "$REDIS_PASSWORD_FILE")"
port="${REDIS_PORT_NUMBER:-6379}"
[ -f "${REDIS_PORT_NUMBER_FILE:-}" ] && port="$(cat "$REDIS_PORT_NUMBER_FILE")"
if [ -n "$pass" ]; then
    [ "$(redis-cli -p "$port" -a "$pass" --no-auth-warning ping 2>/dev/null)" = "PONG" ]
else
    [ "$(redis-cli -p "$port" ping 2>/dev/null)" = "PONG" ]
fi
