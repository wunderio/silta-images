#!/bin/bash
# Minimal file manipulation stubs — replaces Bitnami's libfile.sh
# Used by chart's start-sentinel.sh for sentinel_conf_set -> replace_in_file

# shellcheck disable=SC1091
. /opt/bitnami/scripts/libos.sh

########################
# Replace a regex-matching string in a file
# Arguments:
#   $1 - filename
#   $2 - match regex
#   $3 - substitute regex
#   $4 - use POSIX regex (default: true)
########################
replace_in_file() {
    local filename="${1:?filename is required}"
    local match_regex="${2:?match regex is required}"
    local substitute_regex="${3:?substitute regex is required}"
    local posix_regex=${4:-true}

    local result
    local -r del=$'\001'
    if [[ $posix_regex = true ]]; then
        result="$(sed -E "s${del}${match_regex}${del}${substitute_regex}${del}g" "$filename")"
    else
        result="$(sed "s${del}${match_regex}${del}${substitute_regex}${del}g" "$filename")"
    fi
    echo "$result" > "$filename"
}
