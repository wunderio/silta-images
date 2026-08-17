#!/bin/bash
#
# Run bump-dependabot-image.sh over every currently-open dependabot docker
# image PR. Default is a dry run (report only); pass --apply and/or --push
# to forward those flags to each per-PR invocation.
#
# Usage:
#   ./bump-all-dependabot-images.sh [--apply] [--push]
#
# See docs/dependabot-image-bumps.md for the full explanation.

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

PRS=$(gh pr list --search "is:open" --json number,headRefName --limit 200 \
  | python3 -c '
import json, sys
for pr in json.load(sys.stdin):
    if pr["headRefName"].startswith("dependabot/docker/"):
        print(pr["number"])
')

if [ -z "$PRS" ]; then
  echo "No open dependabot/docker/* PRs found."
  exit 0
fi

FAILED=()
STALE=()
NEEDS_ATTENTION=()

for pr in $PRS; do
  echo "=================================================================="
  echo "=== PR #$pr ==="
  echo "=================================================================="
  set +e
  OUTPUT=$(./bump-dependabot-image.sh "$pr" "$@" 2>&1)
  STATUS=$?
  set -e
  echo "$OUTPUT"
  if [ $STATUS -ne 0 ]; then
    FAILED+=("$pr")
  elif echo "$OUTPUT" | grep -q "is stale/redundant"; then
    STALE+=("$pr")
  elif echo "$OUTPUT" | grep -qE "NOTRIGGER|already drifted"; then
    NEEDS_ATTENTION+=("$pr")
  fi
done

echo "=================================================================="
echo "Summary"
echo "  Failed:          ${FAILED[*]:-none}"
echo "  Stale/redundant: ${STALE[*]:-none}"
echo "  Needs a look:    ${NEEDS_ATTENTION[*]:-none}   (no-trigger TAGS or drift found)"