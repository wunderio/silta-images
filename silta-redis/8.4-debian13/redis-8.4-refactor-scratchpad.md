# Refactor Scratchpad: silta-redis 8.4 — Bitnami-free

## Source image
- Image: `redis:8.4.2` (Docker Official) with Bitnami compat layer
- Source Dockerfile: `silta-redis/8.4-bc/Dockerfile`
- Bitnami scripts: commit `903afb7338c707fe34a6987ac5b5ea4c2e18ec42`, path `bitnami/redis/8.4/debian-12`

## Refactored image
- Base: `dhi.io/redis:8.4-debian13-dev` (DHI hardened)
- Approach: Minimal stubs replacing Bitnami libraries (~120 lines vs ~2000)
- No runtime download of Bitnami containers repo

---

## Key finding: Helm chart overrides ENTRYPOINT/CMD

The Bitnami Redis Helm chart (19.1.5) sets `command: ["/bin/bash"]` and `args: ["-c", "/opt/bitnami/scripts/start-scripts/start-master.sh"]` on the container. This completely bypasses the image's ENTRYPOINT and CMD.

The chart injects its own scripts via ConfigMaps:
- `scripts-configmap.yaml` → mounted at `/opt/bitnami/scripts/start-scripts/`
- `health-configmap.yaml` → mounted at `/health/`
- `configmap.yaml` → mounted at `/opt/bitnami/redis/mounted-etc/`

### What the chart's start scripts need from the image

| Requirement | Non-sentinel | Sentinel | Provided by |
|---|---|---|---|
| `redis-server` in PATH | yes | yes | DHI base + symlinks |
| `redis-cli` in PATH | yes (health) | yes (health + discovery) | DHI base + symlinks |
| `bash` | yes | yes | DHI -dev base |
| `timeout` command | yes (health) | yes (health) | procps package |
| `openssl` | no | yes (host_id) | openssl package |
| `getent` | no | yes (DNS resolution) | libc |
| `sed`, `awk` | yes | yes | DHI base |
| `/opt/bitnami/scripts/libos.sh` | no | yes | stub |
| `/opt/bitnami/scripts/liblog.sh` | no | yes | stub |
| `/opt/bitnami/scripts/libvalidations.sh` | no | yes | stub |
| `/opt/bitnami/scripts/libfile.sh` | no | yes (sentinel) | stub |
| Writable `/opt/bitnami/redis/etc/` | yes | yes | chart emptyDir |
| Writable `/data` | yes | yes | chart PVC |
| Writable `/tmp` | yes | yes | chart emptyDir |

### Functions used by chart scripts (traced from templates)

**From liblog.sh:** `info`, `debug`, `error`, `debug_execute`
**From libos.sh:** `is_boolean_yes`, `retry_while`, `stderr_print`
**From libvalidations.sh:** sourced but no direct calls in non-sentinel scripts
**From libfile.sh:** `replace_in_file` (sentinel_conf_set in start-sentinel.sh)

---

## Directory contract (from Helm chart volume mounts)

| Path | Chart mount type | Purpose |
|---|---|---|
| `/opt/bitnami/scripts/start-scripts/` | ConfigMap (rwx 0755) | Chart-injected start scripts |
| `/health/` | ConfigMap (rwx 0755) | Health check scripts |
| `/opt/bitnami/redis/mounted-etc/` | ConfigMap (ro) | redis.conf, master.conf, replica.conf |
| `/opt/bitnami/redis/etc/` | emptyDir (rw) | Writable copy of config (start scripts copy here) |
| `/opt/bitnami/redis/secrets/` | Secret (ro) | redis-password file |
| `/opt/bitnami/redis/certs/` | Secret (ro, 0400) | TLS certs |
| `/opt/bitnami/redis-sentinel/etc/` | emptyDir (rw) | Sentinel config |
| `/data` | PVC | Persistent data (master.persistence.path) |
| `/tmp` | emptyDir (rw) | Temp (readOnlyRootFilesystem: true) |

---

## Security context contract

```yaml
podSecurityContext:
  fsGroup: 1001
containerSecurityContext:
  runAsUser: 1001
  runAsGroup: 1001
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop: ["ALL"]
```

---

## Environment variables set by chart

| Variable | Set by | Consumed by |
|---|---|---|
| `BITNAMI_DEBUG` | chart | liblog.sh (debug function) |
| `REDIS_REPLICATION_MODE` | chart | start-node.sh (sentinel) |
| `ALLOW_EMPTY_PASSWORD` | chart | image entrypoint (not used in chart mode) |
| `REDIS_PASSWORD` / `REDIS_PASSWORD_FILE` | chart secret | start scripts, health scripts |
| `REDIS_MASTER_PASSWORD` / `REDIS_MASTER_PASSWORD_FILE` | chart secret | replica/sentinel scripts |
| `REDIS_PORT` | chart | start-master.sh, health scripts |
| `REDIS_TLS_ENABLED` | chart | start-node.sh, health scripts |
| `REDIS_TLS_PORT` | chart | start scripts (TLS mode) |
| `REDIS_TLS_CERT_FILE` | chart | start scripts (TLS mode) |
| `REDIS_TLS_KEY_FILE` | chart | start scripts (TLS mode) |
| `REDIS_TLS_CA_FILE` | chart | start scripts (TLS mode) |
| `REDIS_TLS_AUTH_CLIENTS` | chart | start scripts (TLS mode) |
| `REDIS_MASTER_HOST` | chart | replica/sentinel scripts |
| `REDIS_MASTER_PORT_NUMBER` | chart | replica/sentinel scripts |
| `REDIS_DATA_DIR` | chart | sentinel start-node.sh |

---

## What was removed from the original Dockerfile

| Removed | Why |
|---|---|
| `BITNAMI_CONTAINERS_COMMIT` ARG | No longer downloading Bitnami repo |
| `BITNAMI_FILES_PATH` ARG | No longer downloading Bitnami repo |
| `curl` package | Only needed for Bitnami download |
| `curl ... \| tar -xz` RUN | Replaced by COPY of local stubs |
| `postunpack.sh` execution | Config defaults set directly by sed |
| `BITNAMI_APP_NAME` env | Only used by welcome page (no-op stub) |
| `BITNAMI_IMAGE_VERSION` env | Only used by welcome page (no-op stub) |
| `DISABLE_WELCOME_MESSAGE` env | No welcome page to suppress |

## What was added

| Added | Why |
|---|---|
| `openssl` package | Used by sentinel start-sentinel.sh `host_id()` function |
| Guard on user creation | Prevents duplicate /etc/passwd entries |
| `REDIS_PORT` env default | Chart's health scripts reference it |
| `REDIS_DATA_DIR` env default | Chart's sentinel scripts reference it |
| Explicit symlinks per binary | Rather than wildcard glob, explicit is safer |

---

## Test results (2026-03-31)

### Level 1 — Standalone docker run

| Test | Result |
|---|---|
| Build | Clean |
| Startup | `Ready to accept connections tcp` |
| PING with auth | PONG |
| Wrong password | Rejected correctly |
| UID/GID | 1001:1001 |
| PID 1 | redis-server |
| Library stubs load | All 6 files OK |
| `is_boolean_yes` | Correct for yes/no |
| Directories exist | All 9 chart paths confirmed |
| Graceful shutdown | 0.2s |

### Level 2 — Chart-simulated (read-only rootfs, entrypoint override)

| Test | Result |
|---|---|
| Starts with `--read-only --user 1001:1001` | OK |
| Config copied from etc.default | OK (needs `uid=1001` on tmpfs) |
| PING | PONG |
| SET/GET | OK |

### Level 3 — Helm chart on GKE (cluster: silta-dev, namespace: peeter-test)

Image: `wunderio/silta-redis:8.4-debian13-v3-test`
Chart: `redis-19.1.5` (forked Bitnami)

**Standalone mode:**
| Test | Result |
|---|---|
| Pod Ready | 1/1 Running |
| Health probes | Pass (`--wait` succeeded) |
| PING | PONG |
| SET/GET | OK |
| UID | 1001 |
| PID 1 | redis-server |

**Replication mode (master + 1 replica):**
| Test | Result |
|---|---|
| Both pods Ready | 1/1 Running |
| Master role | `role:master`, `connected_slaves:1` |
| Replica state | `state=online, lag=0` |
| Data replication | Master SET → Replica GET = correct |

**Sentinel mode:** Not tested. Stubs are in place but needs verification.
