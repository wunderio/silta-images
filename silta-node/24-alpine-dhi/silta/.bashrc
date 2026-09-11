#!/bin/sh

source /silta/entrypoints/00-umask.sh

if [ "${PS1-}" ]; then
    PS1="\w$ "
fi
