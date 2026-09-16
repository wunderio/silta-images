# Keeping silta-cicd's hand-pinned tool versions current

`silta-cicd/*/Dockerfile` installs Node.js, Yarn, Helm and (on the hardened
node22+ variants) the AWS CLI via a bare `ENV <TOOL>_VERSION ...` + `curl`,
not through a package manager. Dependabot's `docker` ecosystem only ever
parses `FROM` lines (see [dependabot-image-bumps.md](dependabot-image-bumps.md)
for that story), so none of these four ever get an automated bump PR - left
alone they drift indefinitely. `bump-cicd-tool-versions.py` is the missing
automation.

## What it does

For every `silta-cicd/*/Dockerfile`, it checks each pinned tool against
upstream and, with `--apply`:

- Bumps `NODE_VERSION` / `YARN_VERSION` / `HELM_VERSION` / `AWSCLI_VERSION`
  to the latest release **within the same major line already pinned** - it
  never crosses a major on its own (Node 22 stays on 22.x, Helm stays on
  v3.x, AWS CLI stays on 2.x). A major bump is a deliberate decision for a
  human, not something to automate.
- Recomputes the hardcoded `YARN_SHA256` / `AWSCLI_SHA256` checksum when
  present (only the node22+ variants have these - see
  `docs/DHI_AVAILABILITY.md`'s silta-cicd section for why Node/Helm don't
  need a hardcoded hash: their checksum is fetched fresh from upstream and
  verified at build time instead).
- Bumps that directory's `TAGS` build counter (`+1` on the trailing patch,
  e.g. `...-v1.8.1` -> `...-v1.8.2`) - **required** for the change to
  actually publish. `.github/workflows/docker-images.yml` only builds and
  pushes on a `TAGS` diff; a Dockerfile-only edit is silently inert. See
  "Why more than the `FROM` line" in
  [dependabot-image-bumps.md](dependabot-image-bumps.md) for the full
  explanation of this repo's TAGS convention.
- Flags (but does not touch) a Node major that is past its documented EOL
  (checked against `nodejs/Release`'s `schedule.json`) - nothing will ever
  be bumped for it, so the flag is a prompt to retire the directory instead.

## Usage

```sh
# Dry run - report only, touches nothing
docs/bump-cicd-tool-versions.py

# Write the bumps to disk (Dockerfile + TAGS)
docs/bump-cicd-tool-versions.py --apply
```

It does not touch git - review with `git diff` and commit/push yourself.
Pushing a `TAGS` change to `master` (or any branch this workflow watches)
**will** trigger a real build-and-push to Docker Hub for that image, so
treat `--apply` output the same as any other release: review the diff
before committing.

It is idempotent and safe to run repeatedly (e.g. on a schedule) - a
directory with nothing new upstream reports "up to date" and is left alone.
