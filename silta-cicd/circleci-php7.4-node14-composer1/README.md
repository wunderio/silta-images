# silta-circleci
A docker image used circleCI, based on `circleci/php:7.4-cli-node` with the following additions:

- Composer configured correctly
- Drush-launcher, prestissimo and coder pre-installed
- Vim, useful for debugging
- The google cloud cli, kubernetes and helm

## Versions
- PHP: 7.4.12
- Composer: 1.x
- Node: 14.15.1
- GCloud: 392.0.0-0
- Helm: v3.6.3
