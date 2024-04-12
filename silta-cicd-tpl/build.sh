#!/bin/bash

set -eo pipefail

docker build --build-arg="PHP_VERSION=8.1.23" . --tag circleci-php8.1-node18-composer2-v1.3.0 --tag circleci-php8.1-node18-composer2-v1.3 --tag circleci-php8.1-node18-composer2-v1
docker build --build-arg="PHP_VERSION=8.2.12" . --tag circleci-php8.2-node18-composer2-v1.3.0 --tag circleci-php8.2-node18-composer2-v1.3 --tag circleci-php8.2-node18-composer2-v1
docker build --build-arg="PHP_VERSION=8.2.13" . --tag circleci-php8.2-node20-composer2-v1.2.0 --tag circleci-php8.2-node20-composer2-v1.2 --tag circleci-php8.2-node20-composer2-v1
