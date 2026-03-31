#!/bin/bash
# Minimal OS stubs — replaces Bitnami's libos.sh
# Only the functions used by the Helm chart's ConfigMap scripts.

# shellcheck disable=SC1091
. /opt/bitnami/scripts/liblog.sh

########################
# Check if running as root
########################
am_i_root() {
    [[ "$(id -u)" -eq 0 ]]
}

########################
# Check if a boolean value is "yes"
# Used heavily by chart scripts for TLS/auth checks
########################
is_boolean_yes() {
    local -r value="${1:-}"
    [[ "$value" =~ ^(yes|true|1)$ ]]
}

########################
# Retry a command until it succeeds or max retries reached
# Used by sentinel scripts for master discovery
# Arguments:
#   $1 - command (string, eval'd)
#   $2 - max retries (default: 12)
#   $3 - sleep interval in seconds (default: 5)
########################
retry_while() {
    local command="${1:?command required}"
    local retries="${2:-12}"
    local sleep_time="${3:-5}"
    local attempt=0

    while ! eval "$command"; do
        attempt=$((attempt + 1))
        if [[ $attempt -ge $retries ]]; then
            error "Command failed after $retries attempts: $command"
            return 1
        fi
        debug "Retry $attempt/$retries in ${sleep_time}s..."
        sleep "$sleep_time"
    done
}

########################
# Run a command as a specific user (used when running as root)
########################
exec_as_user() {
    local user="${1:?user required}"
    shift
    if am_i_root; then
        su -s /bin/bash "$user" -c "$(printf '%q ' "$@")"
    else
        "$@"
    fi
}

########################
# Ensure a user exists (used by setup.sh, not chart scripts)
########################
ensure_user_exists() {
    local user="${1:?user required}"
    if ! id "$user" &>/dev/null; then
        debug "User $user does not exist, cannot create (no useradd)"
    fi
}

########################
# stderr_print - used by libfs.sh
########################
stderr_print() {
    printf "%s\n" "$*" >&2
}
