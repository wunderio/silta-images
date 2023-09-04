#!/usr/bin/env sh
set -e

## Run startup scripts
for f in $(dirname "$0")/entrypoints/*.sh; do
  if [ -r $f ]; then
    . "$f"
  fi
done
