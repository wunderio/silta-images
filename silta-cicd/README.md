# Silta CICD images

Most images use CircleCI as base image, with extra additions:

- Composer
- Drush-launcher, prestissimo and coder pre-installed
- Google cloud cli and aws-iam-authenticator
- AWS cli
- AKS cli
- kubectl and helm with required repositories

# Node.js versions defined in the CircleCI base images

The cimg/php:x.x.x-node images look up the current lts version of node.js from
https://github.com/CircleCI-Public/cimg-node/blob/main/ALIASES and will
use the version defined there. That file changes over time with newer versions,
but the base image will have the version that was current at the time when the
image was built and tagged.

To verify which version a certain image tag has, you can
run `docker run --rm cimg/php:8.1.23-node /bin/sh -c "node --version"` (change
the image tag as needed).

Alternatively, you can check the date when the image was tagged
from https://hub.docker.com/r/cimg/php
and lookup the node version from the
[commit history](https://github.com/CircleCI-Public/cimg-node/commits/main/ALIASES)
of the aliases file.
