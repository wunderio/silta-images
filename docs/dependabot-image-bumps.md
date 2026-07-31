# Handling dependabot docker image PRs

Dependabot opens a PR per image directory whenever an upstream base image gets
a new tag (`silta-redis/7.4-bc`, `silta-node/22-alpine`, etc). Each PR only
edits the Dockerfile's `FROM` line. That is not enough to actually ship the
new image: a release requires a `TAGS` file change (see below), and several
image families duplicate the version elsewhere (an `ENV`/`ARG`, a README
table) that dependabot never touches. This doc explains what's needed and how
`bump-dependabot-image.sh` / `bump-all-dependabot-images.sh` automate it.

## Why more than the `FROM` line

### 1. `TAGS` is what actually triggers a release

`.github/workflows/docker-images.yml` only builds and pushes an image when a
push to `master` changes a `**/**/TAGS` file (see its `on.push.paths`). The
build script then pushes **every line** in that `TAGS` file as a literal
Docker tag. Merging a dependabot PR that only touched the `Dockerfile` is a
no-op release-wise — the new base image is never actually built and pushed.

Two different `TAGS` conventions exist in this repo:

- **Pinned-to-upstream** (the Bitnami `-bc` images: redis, mongodb, mariadb,
  rabbitmq, memcached, postgresql): the last line *is* the upstream version,
  e.g. `silta-redis/7.4-bc/TAGS` ends with `7.4.9-bc`. Bumping it means
  substituting the old upstream version for the new one in that line.
- **Independent build counter** (silta-node, silta-cicd, silta-php-fpm,
  silta-backup, silta-proxy, silta-rsync, silta-splash): the last line is a
  `vX.Y.Z`-style counter *unrelated* to the upstream version, e.g.
  `silta-node/22-alpine/TAGS` ends with `22-alpine-v1.4.1`. Bumping it just
  means incrementing the trailing patch number by one, regardless of what the
  upstream version actually changed to.

In both cases, only the **last non-blank line** changes — the earlier lines
(`7-bc`, `7.4-bc`, `22-alpine-v1`, `22-alpine-v1.4`, ...) are floating aliases
that get re-pushed pointing at the new build every time, so they're left as
literal text.

**Known gotcha — `silta-php-fpm/latest/TAGS`:** this file is just the literal
line `latest`, with no patch number to bump at all. There is no way to force
a content diff on it without either changing what tag(s) it publishes (adding
a real second tag line) or accepting that the Dockerfile bump alone won't
auto-publish. Git history shows this already happened once silently (a past
PHP bump to this variant never got a matching `TAGS` change). Treat this one
as a manual decision each time it comes up, not something to automate over.

### 2. Secondary version `ENV`/`ARG` vars

The Bitnami-based `-bc` images (redis, mongodb, mariadb, rabbitmq, memcached,
postgresql) additionally hardcode the version as metadata, independently of
`FROM`:

| Image family | Variable |
|---|---|
| redis, mongodb, memcached, rabbitmq | `ENV BITNAMI_IMAGE_VERSION="X.Y.Z"` |
| mariadb | `ENV APP_VERSION="X.Y.Z"` |
| postgresql | `POSTGRESQL_VERSION="X.Y.Z"` (inside a multi-line `ENV`) |

Because dependabot's PR never touches these, **they drift over time** even on
`master` — e.g. at one point `silta-rabbitmq/4.2-bc`'s `BITNAMI_IMAGE_VERSION`
was `4.2.2` while `FROM` already said `4.2.6`. Always set these to exactly the
new `FROM` version rather than only fixing them when they happen to match the
old one — that also self-heals any pre-existing drift.

### 3. README version tables/prose

- `silta-cicd/<variant>/README.md` has a `## Versions` section with a
  `- PHP: X.Y.Z` line (and, for the oldest variant, the PHP version also
  appears in the title prose).
- `silta-php-fpm/README.md` (one file, shared by all `*-fpm` variants) has one
  version-table row per variant, e.g. `` - `8.5-fpm/`: 8.5.6 ``.

Both need the old bare version replaced with the new one.

## The scripts

`bump-dependabot-image.sh <pr-number|branch> [--apply] [--push]` processes
one PR:

1. Resolves the PR number to its branch (`gh pr view`) and fetches it.
2. Checks it out into a **throwaway `git worktree`** (never the main working
   tree — see "the CLAUDE.md pitfall" below for why that matters).
3. Diffs the branch against its merge-base with `origin/master` to find the
   one changed `Dockerfile`, and extracts old/new version from its `FROM`
   line (stripping suffixes like `-alpine`, `-fpm-alpine`, `-management` down
   to the bare `X.Y.Z`).
4. Bumps `TAGS` (auto-detecting which of the two patterns above applies —
   and refusing to touch a bare `latest`-only file, printing a warning
   instead).
5. Syncs any `*_VERSION="..."` Dockerfile var to the new version.
6. Syncs the version string in `README.md` (own directory and one level up).
7. Prints a diff. Without `--apply` it stops there (dry run). With `--apply`
   it commits in the worktree; with `--push` too, it pushes straight to the
   PR branch.

It is **idempotent**: files the branch has already modified (relative to
`origin/master`) are detected via `git diff --name-only` and skipped rather
than re-processed — this matters because the build-counter TAGS pattern has
no way to tell "already bumped" from "never touched" just by looking at the
content, only by checking branch history.

`bump-all-dependabot-images.sh [--apply] [--push]` lists every open
`dependabot/docker/*` PR (`gh pr list`) and runs the above over each one,
printing a final summary of failures, stale PRs (see below), and anything
that needs a manual look (a no-trigger `TAGS`, or a drift-correction).

### Typical usage

```sh
# See what would change across every open dependabot image PR, touch nothing
./bump-all-dependabot-images.sh

# Look at one PR in detail
./bump-dependabot-image.sh 638

# Apply + push everything (after reviewing the dry run output)
./bump-all-dependabot-images.sh --apply --push

# Apply + push a single PR
./bump-dependabot-image.sh 638 --apply --push
```

Always run the dry run first and read the diffs — the scripts flag anomalies
(no-trigger TAGS, drift, stale PRs) but a human still needs to decide what to
do about them.

## Gotchas discovered while building this

- **Never `git add -A` on an old dependabot branch in your main working
  tree.** `CLAUDE.md` is gitignored on current `master`, but that ignore rule
  was added at some point in history; a branch that predates it doesn't have
  the rule, so if a loose `CLAUDE.md` happens to be sitting in your working
  directory (it will be, if you use Claude Code here), `git add -A` will
  silently commit it into that PR. This is exactly what the scripts' use of
  `git worktree add` avoids — the worktree only ever contains that branch's
  own tracked tree, nothing from your main checkout.
- **A PR can go stale/redundant.** If a branch's diff against
  `origin/master` comes up empty (its merge-base already equals its tip
  content-wise — usually because master picked up an equivalent change
  through another route, e.g. someone else's manual bump, and the PR branch
  merged `master` into itself along the way), there's nothing to do; the PR
  should probably just be closed. The script detects this and says so instead
  of failing.
- **Drift compounds if left unfixed.** Since the secondary `ENV` version vars
  are never touched by dependabot, every unattended bump lets them drift a
  little further from `FROM`. Always sync to the *new* target version, not
  just "if it doesn't match the old one".