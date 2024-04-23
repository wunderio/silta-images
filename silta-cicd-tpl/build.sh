#!/bin/bash

# Builds the Docker images with different PHP and Node.js versions.
# Currently, the following versions are supported:
# - PHP versions 8.1 - 8.2
# - Node.js versions 18 - 20
# - Composer version 2

set -eo pipefail

NODE_18="18.20.2"
NODE_20="20.12.2"

docker build --build-arg="PHP_VERSION=8.1" --build-arg="NODE_VERSION=${NODE_18}" . --tag wunderio/silta-cicd:circleci-php8.1-node18-composer2-v1.3.0 --tag wunderio/silta-cicd:circleci-php8.1-node18-composer2-v1.3 --tag wunderio/silta-cicd:circleci-php8.1-node18-composer2-v1
docker build --build-arg="PHP_VERSION=8.2" --build-arg="NODE_VERSION=${NODE_18}" . --tag wunderio/silta-cicd:circleci-php8.2-node18-composer2-v1.3.0 --tag wunderio/silta-cicd:circleci-php8.2-node18-composer2-v1.3 --tag wunderio/silta-cicd:circleci-php8.2-node18-composer2-v1
docker build --build-arg="PHP_VERSION=8.2" --build-arg="NODE_VERSION=${NODE_20}" . --tag wunderio/silta-cicd:circleci-php8.2-node20-composer2-v1.2.0 --tag wunderio/silta-cicd:circleci-php8.2-node20-composer2-v1.2 --tag wunderio/silta-cicd:circleci-php8.2-node20-composer2-v1
