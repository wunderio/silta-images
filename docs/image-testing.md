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
   postgresql, rabbitmq, varnish, mailhog), the trigger passes extra silta
   config files via the `test_silta_config` CircleCI pipeline parameter.
   Those files live in the project repo (e.g. `silta/silta-test-redis.yml`)
   and enable + configure the service under test. The deployment fails (and
   the test with it) if the service pods never become ready.

Images with no entry in `test-matrix.yml` (`silta-cicd`, `silta-backup`,
`silta-rsync`, `silta-proxy`, `silta-splash`) are released without a
downstream test; the PR test-build is their only check.

## Contract with the `*-project-k8s` repos

### 1. Declare the pipeline parameter

```yaml
# .circleci/config.yml
version: 2.1

parameters:
  # Extra silta config files appended by wunderio/silta-images when validating
  # freshly released images (e.g. ",silta/silta-test-redis.yml").
  # Empty on normal runs. Note: the value starts with a comma.
  test_silta_config:
    type: string
    default: ""
```

### 2. Append it to the master deploy job's silta_config

The parameter value carries a **leading comma** (or is empty), so it is
appended directly, without a separator:

```yaml
      # drupal-project-k8s
      - silta/drupal-deploy: &deploy-master
          <<: *deploy
          name: deploy-master
          silta_config: silta/silta.yml,silta/silta-master.yml<< pipeline.parameters.test_silta_config >>
          ...

      # frontend-project-k8s
      - silta/frontend-build-deploy: &build-deploy
          name: 'Build & deploy master'
          silta_config: silta/silta.yml<< pipeline.parameters.test_silta_config >>
          ...
```

Jobs extending these anchors (e.g. "Deploy master to AKS cluster") inherit
the setting automatically. On normal pushes the parameter is empty, so
nothing changes. `simple-project-k8s` needs no changes — only base images
route there, without extra config.

### 3. Provide one test values file per service

Each file only **enables and configures its own service** — see the caveats
below for why it must not disable anything else:

```yaml
# silta/silta-test-redis.yml
# Used when wunderio/silta-images validates a freshly released redis image.
redis:
  enabled: true
  auth:
    password: "testpassword"
```

Files currently referenced by `test-matrix.yml`:

- `drupal-project-k8s`: `silta-test-redis.yml`, `silta-test-memcached.yml`,
  `silta-test-varnish.yml`, `silta-test-solr.yml`, `silta-test-mailhog.yml`
- `frontend-project-k8s`: `silta-test-mongodb.yml`,
  `silta-test-postgresql.yml`, `silta-test-rabbitmq.yml`

## Caveats

- **Test files must not disable other services.** Multiple images can be
  released in one merge, in which case several test files are appended
  together (e.g. `silta-test-redis.yml,silta-test-memcached.yml`) — a file
  that disables "everything else" for speed would clobber the other file's
  service depending on order. Disabling already-running services also buys
  almost nothing: the master environment is long-lived, so its existing
  services (varnish, elasticsearch, ...) are already deployed and add no
  waiting time to an in-place helm upgrade. The only real wait is the new
  service's pods becoming ready — which is exactly what is being tested.
- Triggering the `master` branch with a service enabled changes the project's
  master environment until the next regular deploy reverts it. These are
  shared dev/test projects, so this is accepted; if it becomes a problem,
  point the routing map at a dedicated long-lived branch instead
  (`test-matrix.yml` supports a per-project `branch`).
- A passing deployment proves the service starts and becomes ready, not that
  the application uses it. Deeper smoke tests (e.g. Drupal actually reading
  from redis) belong in the project repos' post-deploy tests.
- A trigger that passes config files to a project that has not declared the
  `test_silta_config` parameter fails with a CircleCI "unknown pipeline
  parameter" error — declare the parameter in the project repo first. The
  workflow only sends the parameter when there are files to append, so plain
  runs (base images) work against unmodified project repos.
- When a chart gains or loses a service, or a new image directory is added,
  update `test-matrix.yml` and add the corresponding test values file in the
  project repo.
