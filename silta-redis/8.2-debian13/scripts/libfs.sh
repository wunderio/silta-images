#!/bin/bash
# Minimal filesystem stubs — replaces Bitnami's libfs.sh
# Used by entrypoint for standalone docker run

# shellcheck disable=SC1091
. /opt/bitnami/scripts/liblog.sh

########################
# Ensure a directory exists
########################
ensure_dir_exists() {
    local dir="${1:?directory is missing}"
    local owner_user="${2:-}"
    local owner_group="${3:-}"

    [ -d "${dir}" ] || mkdir -p "${dir}"
    if [[ -n $owner_user ]]; then
        if [[ -n $owner_group ]]; then
            chown "$owner_user":"$owner_group" "$dir"
        else
            chown "$owner_user":"$owner_user" "$dir"
        fi
    fi
}

########################
# Check if directory is empty
########################
is_dir_empty() {
    local -r path="${1:?missing directory}"
    local -r dir="$(realpath "$path" 2>/dev/null || echo "$path")"
    [[ ! -e "$dir" ]] || [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]
}
