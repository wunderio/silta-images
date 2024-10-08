#!/bin/bash

# AuthorizedKeysCommand does not have environment variables, so we use them with `source`
if [ -f "${0%/*}/gitauth_keys.env" ]; then
    source "${0%/*}/gitauth_keys.env"
fi

# Include static keys if present
if [ -f "${0%/*}/authorized_keys" ]; then
    cat "${0%/*}/authorized_keys"
fi

# Request keys from keyserver
if [[ -n ${GITAUTH_URL} ]]; then
    echo "$(curl -s -u ${GITAUTH_USERNAME}:${GITAUTH_PASSWORD} ${GITAUTH_URL}\?scope=${GITAUTH_SCOPE}\&outside_collaborators=${OUTSIDE_COLLABORATORS}\&fingerprint=${1})"
fi