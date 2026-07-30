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

   The trigger also passes the **released image tag** via the `test_helm_flags`
   parameter — a `--set-string <tag_key>=<tag>` (or `image_ref_key`) flag
   derived from `test-matrix.yml` — so the deployment pins and tests the exact
   image that was just pushed instead of the chart's default tag. Both
   parameters are only sent when non-empty, so plain project pushes are
   unaffected.

Images with no entry in `test-matrix.yml` (`silta-cicd`, `silta-backup`,
`silta-rsync`, `silta-proxy`, `silta-splash`) are released without a
downstream test; the PR test-build is their only check.

## Contract with the `*-project-k8s` repos

### 1. Declare the pipeline parameters

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
  # Helm flags injecting the released image tag, e.g.
  # "--set-string redis.image.tag=7.4-v1.2.3". Empty on normal runs.
  test_helm_flags:
    type: string
    default: ""
```

### 2. Wire both parameters into the master deploy job

#### `test_silta_config` → `silta_config`

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

#### `test_helm_flags` → the deploy job's helm flags

Pass the parameter into the deploy job's helm flags argument (e.g. the silta
orb's `helm_flags` input) so the released tag is applied via `--set-string`.
The value is a standalone flag string (no leading comma) and is empty on
normal runs. Keep the orb's default `--history-max=4` when overriding, since
setting `helm_flags` replaces it:

```yaml
      # drupal-project-k8s
      - silta/drupal-deploy: &deploy-master
          <<: *deploy
          name: deploy-master
          silta_config: silta/silta.yml,silta/silta-master.yml<< pipeline.parameters.test_silta_config >>
          helm_flags: "--history-max=4 << pipeline.parameters.test_helm_flags >>"
          ...

      # frontend-project-k8s
      - silta/frontend-build-deploy: &build-deploy
          name: 'Build & deploy master'
          silta_config: silta/silta.yml<< pipeline.parameters.test_silta_config >>
          helm_flags: "--history-max=4 << pipeline.parameters.test_helm_flags >>"
          ...
```

The `tag_key` / `image_ref_key` in `test-matrix.yml` determines which helm
value the tag is set on.

Jobs extending these anchors (e.g. "Deploy master to AKS cluster") inherit
the settings automatically. On normal pushes both parameters are empty, so
nothing changes. `simple-project-k8s` needs no changes — only base images
route there, without extra config or tag flags.

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
  `test_silta_config` / `test_helm_flags` parameters fails with a CircleCI
  "unknown pipeline parameter" error — declare both parameters in the project
  repo first. The workflow only sends a parameter when it has a non-empty
  value to pass, so plain runs (base images) work against unmodified project
  repos.
- When a chart gains or loses a service, or a new image directory is added,
  update `test-matrix.yml` and add the corresponding test values file in the
  project repo.
