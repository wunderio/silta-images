#!/bin/bash
#
# Add the extra edits a dependabot docker image PR needs beyond its own
# FROM-line bump: the TAGS patch bump (required to trigger
# .github/workflows/docker-images.yml), any secondary version ENV/ARG
# (BITNAMI_IMAGE_VERSION / APP_VERSION), and README version tables.
#
# See docs/dependabot-image-bumps.md for the full explanation of why these
# exist and what each image family looks like.
#
# Usage:
#   ./bump-dependabot-image.sh <pr-number|branch-name> [--apply] [--push]
#
#   (no flags)   dry run: show what would change, do not touch the branch
#   --apply      commit the edits locally (in a scratch worktree)
#   --push       with --apply, also push the commit to the PR branch
#
# Uses a throwaway git worktree so it never touches your working directory
# (in particular: never risks picking up a stray untracked/gitignored file
# like CLAUDE.md the way `git add -A` in the main tree can on older branches).

set -euo pipefail

REF="${1:-}"
APPLY=false
PUSH=false
for arg in "${@:2}"; do
  case "$arg" in
    --apply) APPLY=true ;;
    --push) PUSH=true ;;
    *) echo "Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

if [ -z "$REF" ]; then
  echo "Usage: $0 <pr-number|branch-name> [--apply] [--push]" >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

if [[ "$REF" =~ ^[0-9]+$ ]]; then
  BRANCH=$(gh pr view "$REF" --json headRefName -q .headRefName)
  echo "PR #$REF -> branch $BRANCH"
else
  BRANCH="$REF"
fi

WT_DIR=$(mktemp -d /tmp/silta-bump-XXXXXX)
cleanup() { git -C "$REPO_ROOT" worktree remove --force "$WT_DIR" >/dev/null 2>&1 || true; }
trap cleanup EXIT

# Fetch master and the PR branch as two separate calls so FETCH_HEAD
# unambiguously points at the branch when we use it below.
git fetch -q origin master
git fetch -q origin "$BRANCH"
git worktree add -q --detach "$WT_DIR" FETCH_HEAD

BASE=$(git -C "$WT_DIR" merge-base origin/master HEAD)
CHANGED=$(git -C "$WT_DIR" diff --name-only "$BASE" HEAD)

if [ -z "$CHANGED" ]; then
  echo "No diff against master (merge-base == HEAD content-wise)."
  echo "This branch's changes are already fully contained in master - the PR"
  echo "is stale/redundant. Nothing to do here; consider closing the PR."
  exit 0
fi

DOCKERFILE=$(echo "$CHANGED" | grep '/Dockerfile$' || true)

if [ -z "$DOCKERFILE" ] || [ "$(echo "$DOCKERFILE" | wc -l)" -ne 1 ]; then
  echo "!!! Expected exactly one changed Dockerfile on this branch, got:" >&2
  echo "$CHANGED" >&2
  exit 1
fi

DIR=$(dirname "$DOCKERFILE")
OLD_FROM=$(git -C "$WT_DIR" show "$BASE:$DOCKERFILE" | grep -m1 '^FROM ')
NEW_FROM=$(git -C "$WT_DIR" show HEAD:"$DOCKERFILE" | grep -m1 '^FROM ')
OLD_TAG=${OLD_FROM##*:}
NEW_TAG=${NEW_FROM##*:}
OLD_BARE=$(echo "$OLD_TAG" | grep -oE '^[0-9]+(\.[0-9]+)*' || true)
NEW_BARE=$(echo "$NEW_TAG" | grep -oE '^[0-9]+(\.[0-9]+)*' || true)

echo "Image dir : $DIR"
echo "FROM bump : $OLD_TAG -> $NEW_TAG   (bare: $OLD_BARE -> $NEW_BARE)"

if [ -z "$OLD_BARE" ] || [ -z "$NEW_BARE" ]; then
  echo "!!! Could not extract a bare semver from the FROM tag, aborting." >&2
  exit 1
fi

MODIFIED_FILES=()

# Files other than the Dockerfile that are already different from master on
# this branch - i.e. a previous run of this script (or a manual fix) already
# touched them. Content-pattern matching alone can't reliably tell "already
# bumped" apart from "never touched" (e.g. a patch counter that's unrelated
# to the upstream version), so treat any such file as done and skip it.
ALREADY_CHANGED=$(echo "$CHANGED" | grep -v "^$DOCKERFILE$" || true)
already_changed() {
  echo "$ALREADY_CHANGED" | grep -qxF "$1"
}

# --- 1. TAGS bump -----------------------------------------------------
TAGS_FILE="$DIR/TAGS"
if already_changed "$TAGS_FILE"; then
  echo "TAGS      : already modified on this branch, skipping"
elif [ -f "$WT_DIR/$TAGS_FILE" ]; then
  RESULT=$(python3 - "$WT_DIR/$TAGS_FILE" "$OLD_BARE" "$NEW_BARE" <<'PYEOF'
import re, sys
path, old_bare, new_bare = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    lines = f.read().splitlines()
nonblank = [i for i, l in enumerate(lines) if l.strip()]
if not nonblank:
    print("NOTAGS")
    sys.exit(0)
idx = nonblank[-1]
last = lines[idx]

if old_bare in last:
    new_last = last.replace(old_bare, new_bare)
    lines[idx] = new_last
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"PINNED {last} -> {new_last}")
    sys.exit(0)

m = re.search(r'^(.*-v?)(\d+)\.(\d+)\.(\d+)$', last)
if m:
    prefix, maj, minr, patch = m.groups()
    new_last = f"{prefix}{maj}.{minr}.{int(patch)+1}"
    lines[idx] = new_last
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"COUNTER {last} -> {new_last}")
    sys.exit(0)

print(f"NOTRIGGER {last}")
PYEOF
)
  echo "TAGS      : $RESULT"
  case "$RESULT" in
    PINNED*|COUNTER*) MODIFIED_FILES+=("$TAGS_FILE") ;;
    NOTAGS) echo "    (TAGS file is empty, nothing to bump)" ;;
    NOTRIGGER*)
      echo "    !!! Last line has no version counter to bump (e.g. a bare"
      echo "        'latest' tag) - merging as-is will NOT trigger"
      echo "        docker-images.yml. Decide manually: add a versioned"
      echo "        tag line, or accept it won't auto-publish."
      ;;
  esac
else
  echo "TAGS      : no TAGS file at $TAGS_FILE"
fi

# --- 2. Secondary version ENV/ARG (e.g. BITNAMI_IMAGE_VERSION, APP_VERSION,
# POSTGRESQL_VERSION - any quoted "*_VERSION" that duplicates the FROM tag) ---
if grep -qE '[A-Z_]+_VERSION="[0-9]' "$WT_DIR/$DOCKERFILE"; then
  RESULT=$(python3 - "$WT_DIR/$DOCKERFILE" "$NEW_BARE" <<'PYEOF'
import re, sys
path, new_bare = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()
pattern = re.compile(r'([A-Z_]+_VERSION)="([0-9][^"]*)"')
m = pattern.search(content)
old_val = m.group(2)
if old_val == new_bare:
    print(f"INSYNC {m.group(1)}={old_val}")
else:
    content2 = pattern.sub(lambda mo: f'{mo.group(1)}="{new_bare}"', content, count=1)
    with open(path, "w") as f:
        f.write(content2)
    print(f"SYNCED {m.group(1)} {old_val} -> {new_bare}")
PYEOF
)
  echo "ENV var   : $RESULT"
  case "$RESULT" in
    SYNCED*)
      MODIFIED_FILES+=("$DOCKERFILE")
      if [[ "$RESULT" != *"$OLD_BARE"* ]]; then
        echo "    (was already drifted from the previous FROM version - corrected)"
      fi
      ;;
  esac
fi

# --- 3. README version references -------------------------------------
for README in "$DIR/README.md" "$(dirname "$DIR")/README.md"; do
  [ -f "$WT_DIR/$README" ] || continue
  if already_changed "$README"; then
    echo "README    : $README already modified on this branch, skipping"
  elif grep -qF "$OLD_BARE" "$WT_DIR/$README"; then
    python3 - "$WT_DIR/$README" "$OLD_BARE" "$NEW_BARE" <<'PYEOF'
import sys
path, old_bare, new_bare = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    content = f.read()
with open(path, "w") as f:
    f.write(content.replace(old_bare, new_bare))
PYEOF
    echo "README    : updated $README ($OLD_BARE -> $NEW_BARE)"
    MODIFIED_FILES+=("$README")
  fi
done

echo
echo "--- diff ---"
git -C "$WT_DIR" diff --stat
git -C "$WT_DIR" diff

if [ ${#MODIFIED_FILES[@]} -eq 0 ]; then
  echo "Nothing to change."
  exit 0
fi

if [ "$APPLY" != true ]; then
  echo
  echo "(dry run - rerun with --apply to commit, add --push to also publish)"
  exit 0
fi

git -C "$WT_DIR" add -- "${MODIFIED_FILES[@]}"
git -C "$WT_DIR" commit -q -m "Bump TAGS/version metadata alongside dependency update"
echo "Committed locally in worktree ($(git -C "$WT_DIR" rev-parse --short HEAD))."

if [ "$PUSH" = true ]; then
  git -C "$WT_DIR" push origin "HEAD:$BRANCH"
  echo "Pushed to $BRANCH."
else
  echo "Not pushed (pass --push to publish to $BRANCH)."
fi