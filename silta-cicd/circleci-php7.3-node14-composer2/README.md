# silta-circleci
A docker image used circleCI, based on `circleci/php:7.3-cli-node` with the following additions:

- Composer configured correctly
- Drush-launcher, prestissimo and coder pre-installed
- Vim, useful for debugging
- kubernetes and helm

## Versions
- PHP: 7.3.23
- Composer: 2.x
- Node: 14.15.0
- Helm: v3.14.0
