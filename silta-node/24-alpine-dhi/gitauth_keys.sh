#!/bin/bash

# AuthorizedKeysCommand does not have environment variables, so we use them with `source`
source "${0%/*}/gitauth_keys.env"

echo "$(curl -s -u ${GITAUTH_USERNAME}:${GITAUTH_PASSWORD} ${GITAUTH_URL}\?scope=${GITAUTH_SCOPE}\&outside_collaborators=${OUTSIDE_COLLABORATORS}\&fingerprint=${1})"