#!/bin/bash
# Minimal logging stubs — replaces Bitnami's liblog.sh
# Only the functions used by the Helm chart's ConfigMap scripts.

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'

_log() {
    local color="$1"; shift
    local level="$1"; shift
    printf "${color}%s [%s] %s${RESET}\n" "$(date '+%T.%3N')" "$level" "$*" >&2
}

info()  { _log "$GREEN"  "INFO " "$@"; }
warn()  { _log "$YELLOW" "WARN " "$@"; }
error() { _log "$RED"    "ERROR" "$@"; }
debug() {
    if [[ "${BITNAMI_DEBUG:-false}" =~ ^(yes|true|1)$ ]]; then
        _log "$CYAN" "DEBUG" "$@"
    fi
}

# Used by some Bitnami scripts for conditional debug execution
debug_execute() {
    if [[ "${BITNAMI_DEBUG:-false}" =~ ^(yes|true|1)$ ]]; then
        "$@"
    fi
}
