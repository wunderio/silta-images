#!/bin/bash
# Minimal validation stubs — replaces Bitnami's libvalidations.sh
# Sourced by chart's start-node.sh and start-sentinel.sh

# shellcheck disable=SC1091
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libos.sh

########################
# Check if a value is empty
########################
is_empty_value() {
    local -r value="${1:-}"
    [[ -z "$value" || "$value" == "nil" ]]
}

########################
# Validate that an env var is set
########################
validate_not_empty() {
    local var_name="${1:?variable name required}"
    local var_value="${2:-}"
    if is_empty_value "$var_value"; then
        error "The $var_name environment variable is required"
        return 1
    fi
}
