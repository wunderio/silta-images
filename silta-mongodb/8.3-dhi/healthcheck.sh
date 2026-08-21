#!/bin/sh
# Standalone container healthcheck: verify mongod answers an admin ping.
# Used by docker run / docker compose and by CI wait-for-healthy.
# Kubernetes ignores docker HEALTHCHECK; the Helm chart uses its own probes.
# The ping command needs no authentication, so this works whether or not
# MONGODB_ROOT_PASSWORD is set.
mongosh --quiet \
    --host 127.0.0.1 \
    --port "${MONGODB_PORT_NUMBER:-27017}" \
    --eval 'quit(db.adminCommand({ ping: 1 }).ok === 1 ? 0 : 1)' >/dev/null 2>&1