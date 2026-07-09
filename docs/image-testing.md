# Downstream image testing

When a `TAGS` file change is merged to master, `.github/workflows/docker-images.yml`
builds and pushes the image, then validates it by triggering CircleCI pipelines
of the `*-project-k8s` test projects. This document describes how the test
routing works and what the downstream project repos must provide.

## Flow

1. `changed_files` collects the changed `TAGS` files from the push.
2. `build_and_push_docker_hub` builds and pushes every tag listed in each
   changed `TAGS` file.
3. `test_plan` maps each changed image (first path segment, e.g. `silta-redis`)
   to downstream projects using [`test-matrix.yml`](../test-matrix.yml).
   Only the projects that actually consume a changed image are triggered —
   e.g. a `silta-memcached` release does not trigger `simple-project-k8s`.
4. `circleci-k8s-test-build` triggers one CircleCI pipeline per affected
   project and waits for it to finish. When the changed image's service is
   disabled by default in the chart (redis, memcached, solr, mongodb,
   postgresql, rabbitmq, varnish, mailhog), the trigger passes helm `--set`
   flags via the `test_helm_flags` CircleCI pipeline parameter so the test
   deployment actually runs the service. The deployment fails (and the test
   with it) if the service pods never become ready.

Images with no entry in `test-matrix.yml` (`silta-cicd`, `silta-backup`,
`silta-rsync`, `silta-proxy`, `silta-splash`) are released without a
downstream test; the PR test-build is their only check.

## Contract with the `*-project-k8s` repos

Each project repo referenced in `test-matrix.yml` must declare the pipeline
parameter and splice it into the deploy job's helm flags:

```yaml
# .circleci/config.yml
version: 2.1

parameters:
  # Extra helm flags passed by wunderio/silta-images to enable
  # default-disabled services when testing freshly released images.
  test_helm_flags:
    type: string
    default: ""
```

and on the master-branch deploy job (the silta orb's `helm_flags` parameter
defaults to `--history-max=4`, so keep it when overriding):

```yaml
      - silta/drupal-deploy:
          <<: *deploy-master
          helm_flags: "--history-max=4 << pipeline.parameters.test_helm_flags >>"
```

The workflow only sends the parameter when there are services to enable, so
projects that have not declared it yet keep working for plain test runs
(base images such as nginx/php/node). A trigger that does pass services to a
project without the parameter declared fails with a CircleCI "unknown
pipeline parameter" error — declare the parameter in the project repo first.

## Caveats

- Triggering the `master` branch with `--set redis.enabled=true` changes the
  project's master environment until the next regular deploy reverts it.
  These are shared dev/test projects, so this is accepted; if it becomes a
  problem, point the routing map at a dedicated long-lived branch instead
  (`test-matrix.yml` supports a per-project `branch`).
- A passing deployment proves the service starts and becomes ready, not that
  the application uses it. Deeper smoke tests (e.g. Drupal actually reading
  from redis) belong in the project repos' post-deploy tests.
- When a chart gains or loses a service, or a new image directory is added,
  update `test-matrix.yml` accordingly.
