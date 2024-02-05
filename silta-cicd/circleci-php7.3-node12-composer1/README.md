# silta-circleci
A docker image used circleCI, based on `circleci/php:7.3-cli-node` with the following additions:

- Composer configured correctly
- Drush-launcher, prestissimo and coder pre-installed
- Vim, useful for debugging
- kubernetes and helm

## Versions
- PHP: 7.3.19
- Composer: 1.x
- Node: 12.18.2
- Helm: v3.13.3
