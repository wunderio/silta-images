#!/usr/bin/env bash
# test-build.sh — Build and test silta-redis debian13 variants
#
# Usage:
#   ./test-build.sh                  # test all *-debian13 variants
#   ./test-build.sh 8.4 8.6          # test specific versions
#   ./test-build.sh --level 1 8.6    # level 1 only (build + PING)
#   ./test-build.sh --level 2 8.6    # levels 1+2 (+ chart-simulated)
#   ./test-build.sh --level 3 8.6    # levels 1+2+3 (+ comprehensive)
#   ./test-build.sh --no-build 8.6   # skip build, test existing image
#
# Adding a new version (e.g. 8.8):
#   1. mkdir 8.8-debian13 && cp -r 8.4-debian13/scripts 8.8-debian13/
#   2. Copy a sibling Dockerfile, change the FROM tag to dhi.io/redis:8.8-debian13-dev
#   3. Copy the redis-default.conf from the closest version or generate fresh
#   4. Create TAGS file with: 8.8-debian13-v2\n8.8-debian13-v2.0\n8.8-debian13-v2.0.0
#   5. Run: ./test-build.sh 8.8
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LEVEL=3
DO_BUILD=true
VERSIONS=()
PASS_COUNT=0
FAIL_COUNT=0
FAILURES=()

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Helpers ---
log()  { printf "${CYAN}[INFO]${RESET} %s\n" "$*"; }
pass() { printf "${GREEN}  ✓ %s${RESET}\n" "$*"; }
fail() { printf "${RED}  ✗ %s${RESET}\n" "$*"; }
section() { printf "\n${BOLD}--- %s ---${RESET}\n" "$*"; }

check() {
    local label="$1"
    local result="$2"
    local expected="${3:-}"

    if [ -n "$expected" ]; then
        if [[ "$result" == *"$expected"* ]]; then
            pass "$label"
            return 0
        else
            fail "$label (got: '$result', expected: '$expected')"
            return 1
        fi
    else
        if [ -n "$result" ]; then
            pass "$label: $result"
            return 0
        else
            fail "$label: empty/missing"
            return 1
        fi
    fi
}

cleanup_container() {
    local name="$1"
    docker stop "$name" &>/dev/null || true
    docker rm -f "$name" &>/dev/null || true
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --level) TEST_LEVEL="$2"; shift 2 ;;
        --no-build) DO_BUILD=false; shift ;;
        --help|-h)
            sed -n '2,/^$/{ s/^# //; s/^#//; p }' "$0"
            exit 0
            ;;
        *) VERSIONS+=("$1"); shift ;;
    esac
done

# Auto-discover variants if none specified
if [ ${#VERSIONS[@]} -eq 0 ]; then
    for d in "$SCRIPT_DIR"/*-debian13; do
        [ -d "$d" ] && [ -f "$d/Dockerfile" ] && VERSIONS+=("$(basename "$d" | sed 's/-debian13//')")
    done
fi

if [ ${#VERSIONS[@]} -eq 0 ]; then
    echo "No debian13 variants found in $SCRIPT_DIR"
    exit 1
fi

printf "${BOLD}Testing variants: %s (level %s)${RESET}\n" "${VERSIONS[*]}" "$TEST_LEVEL"
echo ""

# --- Per-variant test ---
test_variant() {
    local ver="$1"
    local variant="${ver}-debian13"
    local dir="$SCRIPT_DIR/$variant"
    local image="silta-redis:${variant}-test"
    local name="redis-test-${ver//./-}"
    local errors=0

    printf "\n${BOLD}========================================${RESET}\n"
    printf "${BOLD} Testing: silta-redis %s${RESET}\n" "$variant"
    printf "${BOLD}========================================${RESET}\n"

    if [ ! -d "$dir" ]; then
        fail "Directory $dir not found"
        return 1
    fi

    # ── Build ──
    if $DO_BUILD; then
        section "Build"
        if docker build -t "$image" "$dir" 2>&1 | tail -5; then
            pass "Image built: $image"
        else
            fail "Build failed"
            return 1
        fi
    fi

    # ── Level 1: Standalone smoke test ──
    section "Level 1 — Standalone smoke test"
    cleanup_container "$name"

    docker run --rm -d --name "$name" -e REDIS_PASSWORD=testpass "$image" &>/dev/null
    sleep 2

    # Check container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
        fail "Container failed to start"
        docker logs "$name" 2>&1 | tail -10
        return 1
    fi

    # PING
    local ping
    ping=$(docker exec "$name" redis-cli -a testpass PING 2>/dev/null)
    check "PING" "$ping" "PONG" || ((errors++))

    # UID
    local uid
    uid=$(docker exec "$name" id -u 2>/dev/null)
    check "UID" "$uid" "1001" || ((errors++))

    # PID 1
    local pid1
    pid1=$(docker exec "$name" cat /proc/1/cmdline 2>/dev/null | tr '\0' ' ')
    check "PID 1 is redis-server" "$pid1" "redis-server" || ((errors++))

    # Redis version
    local redis_ver
    redis_ver=$(docker exec "$name" redis-server --version 2>/dev/null | sed -n 's/.*v=\([0-9.]*\).*/\1/p')
    check "Redis version starts with $ver" "$redis_ver" "$ver" || ((errors++))

    cleanup_container "$name"

    [ "$TEST_LEVEL" -lt 2 ] && { _tally $errors "$variant"; return $errors; }

    # ── Level 2: Chart-simulated (read-only rootfs) ──
    section "Level 2 — Chart-simulated mode"
    cleanup_container "$name"

    docker run --rm -d --name "$name" \
        --user 1001:1001 --read-only \
        --tmpfs /tmp:uid=1001,gid=1001 \
        --tmpfs /opt/bitnami/redis/etc:uid=1001,gid=1001 \
        --tmpfs /data:uid=1001,gid=1001 \
        -e REDIS_PORT=6379 \
        -e REDIS_PASSWORD=testpass \
        --entrypoint /bin/bash "$image" \
        -c 'cp /opt/bitnami/redis/etc.default/* /opt/bitnami/redis/etc/ 2>/dev/null; redis-server /opt/bitnami/redis/etc/redis.conf --requirepass "$REDIS_PASSWORD" --daemonize no' \
        &>/dev/null
    sleep 2

    if ! docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
        fail "Container failed to start in chart mode"
        ((errors++))
    else
        # PING
        ping=$(docker exec "$name" redis-cli -a testpass PING 2>/dev/null)
        check "PING (chart mode)" "$ping" "PONG" || ((errors++))

        # SET/GET
        docker exec "$name" redis-cli -a testpass SET l2test "hello" &>/dev/null 2>&1
        local get
        get=$(docker exec "$name" redis-cli -a testpass GET l2test 2>/dev/null)
        check "SET/GET (chart mode)" "$get" "hello" || ((errors++))

        # Read-only rootfs
        local ro_exit
        docker exec "$name" bash -c 'touch /usr/local/test' &>/dev/null 2>&1
        ro_exit=$?
        if [ "$ro_exit" -ne 0 ]; then
            pass "Read-only rootfs enforced"
        else
            fail "Read-only rootfs NOT enforced"
            ((errors++))
        fi
    fi

    cleanup_container "$name"

    [ "$TEST_LEVEL" -lt 3 ] && { _tally $errors "$variant"; return $errors; }

    # ── Level 3: Comprehensive checks ──
    section "Level 3 — Comprehensive image validation"
    cleanup_container "$name"

    docker run --rm -d --name "$name" -e REDIS_PASSWORD=testpass "$image" &>/dev/null
    sleep 2

    # Binaries at chart-expected paths
    for bin in redis-server redis-cli redis-sentinel redis-check-aof redis-check-rdb redis-benchmark; do
        local exists
        exists=$(docker exec "$name" bash -c "test -x '/opt/bitnami/redis/bin/$bin' && echo OK || echo MISSING")
        check "Binary /opt/bitnami/redis/bin/$bin" "$exists" "OK" || ((errors++))
    done

    # System tools
    local tools_result
    tools_result=$(docker exec "$name" bash -c '
        missing=""
        for tool in bash timeout openssl getent sed awk; do
            command -v "$tool" &>/dev/null || missing="$missing $tool"
        done
        if [ -z "$missing" ]; then echo "all present"; else echo "missing:$missing"; fi
    ')
    check "System tools (bash,timeout,openssl,getent,sed,awk)" "$tools_result" "all present" || ((errors++))

    # Library stubs source cleanly
    local stubs_result
    stubs_result=$(docker exec "$name" bash -c '
        ok=0; fail=0
        for lib in liblog.sh libos.sh libvalidations.sh libfile.sh libfs.sh libbitnami.sh; do
            if source "/opt/bitnami/scripts/$lib" 2>/dev/null; then ((ok++)); else ((fail++)); fi
        done
        echo "${ok} OK, ${fail} failed"
    ')
    check "Library stubs source" "$stubs_result" "6 OK, 0 failed" || ((errors++))

    # Key functions exist
    local funcs_result
    funcs_result=$(docker exec "$name" bash -c '
        source /opt/bitnami/scripts/liblog.sh
        source /opt/bitnami/scripts/libos.sh
        source /opt/bitnami/scripts/libvalidations.sh
        source /opt/bitnami/scripts/libfile.sh
        ok=0; missing=""
        for fn in info debug warn error is_boolean_yes retry_while replace_in_file am_i_root is_empty_value; do
            if type "$fn" &>/dev/null; then ((ok++)); else missing="$missing $fn"; fi
        done
        if [ -z "$missing" ]; then echo "${ok}/9 functions defined"; else echo "missing:$missing"; fi
    ')
    check "Stub functions" "$funcs_result" "9/9 functions defined" || ((errors++))

    # Directory contract
    local dirs_result
    dirs_result=$(docker exec "$name" bash -c '
        ok=0; missing=""
        for d in /opt/bitnami/redis/mounted-etc /opt/bitnami/redis/etc /opt/bitnami/redis/etc.default \
                 /opt/bitnami/redis/secrets /opt/bitnami/redis/certs /opt/bitnami/redis-sentinel/etc \
                 /opt/bitnami/scripts/start-scripts /health /data /tmp \
                 /bitnami/redis/conf /bitnami/redis/data /bitnami/redis/logs; do
            if [ -d "$d" ]; then ((ok++)); else missing="$missing $d"; fi
        done
        echo "${ok}/13 dirs"
        [ -n "$missing" ] && echo "missing:$missing"
    ')
    check "Directory contract" "$dirs_result" "13/13 dirs" || ((errors++))

    # Ownership
    local owner_result
    owner_result=$(docker exec "$name" bash -c '
        bad=""
        for d in /opt/bitnami/redis/etc /opt/bitnami/redis/etc.default /opt/bitnami/redis/secrets \
                 /opt/bitnami/redis/certs /opt/bitnami/redis-sentinel/etc /data \
                 /bitnami/redis/conf /bitnami/redis/data /bitnami/redis/logs; do
            owner=$(stat -c "%u" "$d" 2>/dev/null)
            [ "$owner" = "1001" ] || bad="$bad $d($owner)"
        done
        if [ -z "$bad" ]; then echo "all 1001"; else echo "wrong:$bad"; fi
    ')
    check "Directory ownership" "$owner_result" "all 1001" || ((errors++))

    # Config
    local config_result
    config_result=$(docker exec "$name" bash -c '
        port=$(grep "^port " /opt/bitnami/redis/etc/redis.conf 2>/dev/null | awk "{print \$2}")
        dir=$(grep "^dir " /opt/bitnami/redis/etc/redis.conf 2>/dev/null | awk "{print \$2}")
        echo "port=$port dir=$dir"
    ')
    check "Default config" "$config_result" "port=6379 dir=/data" || ((errors++))

    # Env vars
    for var_check in "REDIS_PORT=6379" "REDIS_DATA_DIR=/data" "BITNAMI_DEBUG=false"; do
        local var_name="${var_check%%=*}"
        local var_expected="${var_check#*=}"
        local var_actual
        var_actual=$(docker exec "$name" printenv "$var_name" 2>/dev/null)
        check "ENV $var_name" "$var_actual" "$var_expected" || ((errors++))
    done

    # PATH includes /opt/bitnami/redis/bin
    local path_val
    path_val=$(docker exec "$name" printenv PATH 2>/dev/null)
    check "PATH includes redis bin" "$path_val" "/opt/bitnami/redis/bin" || ((errors++))

    # Entrypoint symlink
    local ep_link
    ep_link=$(docker exec "$name" readlink -f /entrypoint.sh 2>/dev/null)
    check "Entrypoint symlink" "$ep_link" "/opt/bitnami/scripts/entrypoint.sh" || ((errors++))

    # User/group
    local user_check
    user_check=$(docker exec "$name" bash -c 'grep "^redis:x:1001:1001" /etc/passwd && echo "user OK"' 2>/dev/null)
    check "User redis:1001:1001 in /etc/passwd" "$user_check" "user OK" || ((errors++))

    # SUID/SGID
    local suid
    suid=$(docker exec "$name" find / -perm /6000 -type f 2>/dev/null | head -1)
    if [ -z "$suid" ]; then
        pass "No SUID/SGID binaries"
    else
        fail "SUID/SGID found: $suid"
        ((errors++))
    fi

    # Wrong password rejected
    local wrong_pw
    wrong_pw=$(docker exec "$name" redis-cli -a wrongpass PING 2>/dev/null)
    if echo "$wrong_pw" | grep -qi "WRONGPASS\|NOAUTH\|ERR"; then
        pass "Wrong password rejected"
    else
        fail "Wrong password NOT rejected (got: $wrong_pw)"
        ((errors++))
    fi

    cleanup_container "$name"
    _tally $errors "$variant"
    return $errors
}

_tally() {
    local errors="$1"
    local variant="$2"
    echo ""
    if [ "$errors" -eq 0 ]; then
        printf "${GREEN}${BOLD}  ▶ %s: ALL TESTS PASSED${RESET}\n" "$variant"
        ((PASS_COUNT++))
    else
        printf "${RED}${BOLD}  ▶ %s: %d TEST(S) FAILED${RESET}\n" "$variant" "$errors"
        ((FAIL_COUNT++))
        FAILURES+=("$variant")
    fi
}

# --- Run ---
for ver in "${VERSIONS[@]}"; do
    test_variant "$ver" || true
done

# --- Summary ---
printf "\n${BOLD}========================================${RESET}\n"
printf "${BOLD} SUMMARY${RESET}\n"
printf "${BOLD}========================================${RESET}\n"
printf "  Variants tested: %d\n" "$(( PASS_COUNT + FAIL_COUNT ))"
printf "  ${GREEN}Passed: %d${RESET}\n" "$PASS_COUNT"
printf "  ${RED}Failed: %d${RESET}\n" "$FAIL_COUNT"
if [ ${#FAILURES[@]} -gt 0 ]; then
    printf "  Failed variants: %s\n" "${FAILURES[*]}"
fi
echo ""

[ "$FAIL_COUNT" -eq 0 ]
