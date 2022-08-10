# silta-circleci
A docker image used circleCI, based on `circleci/php:7.4-cli-node` with the following additions:

- Composer configured correctly
- Drush-launcher and coder pre-installed
- Vim, useful for debugging
- The google cloud cli, kubernetes and helm

## Versions
- PHP: 8.0.1
- Composer: 2.x
- Node: 14.15.4
- GCloud: 348.0.0-0
- Helm: v3.6.3
