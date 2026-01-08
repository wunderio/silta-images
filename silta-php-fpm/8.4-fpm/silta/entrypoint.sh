#!/usr/bin/env sh
set -e

## Run startup scripts
for f in $(dirname "$0")/entrypoints/*.sh; do
  if [ -r $f ]; then
    . "$f"
  fi
done

## Run passed cmd
if [ ! -z "$1" ]; then
  exec "$@"
fi
