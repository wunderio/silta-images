#!/bin/sh
# This script is executed by the main docker-entrypoint.sh
# It checks for a mirror URL and starts GoReplay in the background.

set -e

# Check if the GOR_MIRROR_URL environment variable is set and not empty
if [ -n "$GOR_MIRROR_URL" ]; then
    echo "$(date): Starting GoReplay - Mirroring traffic to $GOR_MIRROR_URL"

    # Launch GoReplay in the background (&)
    #
    # IMPORTANT: The --input-raw port must match the port your NGINX is listening on
    # inside the container. For the nginx-unprivileged image, this is 8080 by default.
    # Adjust if your nginx.conf listens on a different port.
    /usr/local/bin/gor --input-raw :8080 --output-http "$GOR_MIRROR_URL" &

else
    echo "$(date): GOR_MIRROR_URL not set, skipping GoReplay."
fi

# The script will now exit, and the main entrypoint will continue to start NGINX.
