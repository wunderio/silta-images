# silta-circleci
A docker image used circleCI, based on `circleci/php:7.2-cli-node` with the following additions:

- Composer configured correctly
- Drush-launcher, prestissimo and coder pre-installed
- Vim, useful for debugging
- kubernetes and helm

## Versions
- PHP: 7.2.34
- Composer: 1.x
- Node: 14.15.2
- Helm: v3.14.0
