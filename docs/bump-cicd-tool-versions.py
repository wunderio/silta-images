#!/usr/bin/env python3
"""
Bump the hand-pinned tool versions inside silta-cicd/*/Dockerfile.

silta-cicd images install Node.js, Yarn, Helm and (where hardened) the AWS
CLI via a bare `ENV <TOOL>_VERSION ...` + `curl`, not via a package manager.
Dependabot's docker ecosystem only ever looks at `FROM` lines, so none of
these ever get an automated bump PR - left alone they drift indefinitely.
This script is that missing automation: for every silta-cicd variant it
checks each pinned tool against upstream, and with --apply bumps the ENV
line(s) (recomputing any hardcoded sha256 checksum) plus that directory's
TAGS build counter, so the change actually triggers a release build (see
docs/dependabot-image-bumps.md for why TAGS has to move too - Dockerfile
edits alone are silently inert).

Never crosses a major version on its own: Node stays on whatever major is
already pinned (22.x stays 22.x), Helm stays on v3.x, AWS CLI stays on 2.x.
A major bump is a deliberate decision for a human, not something to automate.

A pinned Node line whose major is already past its documented Node.js EOL
(nothing newer will ever be released for it - e.g. Node 23) is flagged but
left alone; there is nothing to bump.

Usage:
  docs/bump-cicd-tool-versions.py               # dry run, print a report
  docs/bump-cicd-tool-versions.py --apply       # write changes to disk

Dry run touches nothing and needs no confirmation. --apply writes directly
to the working tree (Dockerfile + TAGS) - review with `git diff` and commit
yourself; this script does not touch git.
"""
import argparse
import datetime
import hashlib
import json
import re
import sys
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CICD_DIR = REPO_ROOT / "silta-cicd"
HEADERS = {"User-Agent": "silta-images-bump-cicd-tool-versions"}


def fetch(url):
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read()


def fetch_json(url):
    return json.loads(fetch(url))


def sha256_of_url(url):
    h = hashlib.sha256()
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=180) as r:
        while True:
            chunk = r.read(1 << 20)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def vtuple(v):
    return tuple(int(x) for x in v.split("."))


# --- upstream lookups, cached so N directories pinning the same version
# only cost one network round-trip / one checksum download -----------------

_node_index = None


def node_latest_patch(major):
    global _node_index
    if _node_index is None:
        _node_index = fetch_json("https://nodejs.org/dist/index.json")
    candidates = [r["version"][1:] for r in _node_index if r["version"].startswith(f"v{major}.")]
    return max(candidates, key=vtuple) if candidates else None


_node_schedule = None


def node_is_eol(major):
    global _node_schedule
    if _node_schedule is None:
        _node_schedule = fetch_json(
            "https://raw.githubusercontent.com/nodejs/Release/main/schedule.json"
        )
    entry = _node_schedule.get(f"v{major}")
    if not entry or "end" not in entry:
        return False
    return entry["end"] < datetime.date.today().isoformat()


_yarn_releases = None


def yarn_latest_1x():
    global _yarn_releases
    if _yarn_releases is None:
        _yarn_releases = fetch_json("https://api.github.com/repos/yarnpkg/yarn/releases?per_page=100")
    candidates = [
        r["tag_name"][1:] for r in _yarn_releases if re.match(r"^v1\.\d+\.\d+$", r["tag_name"])
    ]
    return max(candidates, key=vtuple) if candidates else None


_yarn_sha_cache = {}


def yarn_sha256(version):
    if version not in _yarn_sha_cache:
        url = f"https://yarnpkg.com/downloads/{version}/yarn-v{version}.tar.gz"
        _yarn_sha_cache[version] = sha256_of_url(url)
    return _yarn_sha_cache[version]


_helm_releases = None


def helm_latest(major):
    global _helm_releases
    if _helm_releases is None:
        _helm_releases = fetch_json("https://api.github.com/repos/helm/helm/releases?per_page=100")
    candidates = [
        r["tag_name"][1:] for r in _helm_releases if re.match(rf"^v{major}\.\d+\.\d+$", r["tag_name"])
    ]
    return max(candidates, key=vtuple) if candidates else None


_awscli_tags = None


def awscli_latest(major):
    global _awscli_tags
    if _awscli_tags is None:
        _awscli_tags = fetch_json("https://api.github.com/repos/aws/aws-cli/tags?per_page=100")
    candidates = [t["name"] for t in _awscli_tags if re.match(rf"^{major}\.\d+\.\d+$", t["name"])]
    return max(candidates, key=vtuple) if candidates else None


_awscli_sha_cache = {}


def awscli_sha256(version):
    if version not in _awscli_sha_cache:
        url = f"https://awscli.amazonaws.com/awscli-exe-linux-x86_64-{version}.zip"
        _awscli_sha_cache[version] = sha256_of_url(url)
    return _awscli_sha_cache[version]


# --- per-Dockerfile bump ----------------------------------------------------


def bump_dockerfile(text, lines):
    """Return (new_text, changed). Appends human-readable notes to `lines`."""
    changed = False

    m = re.search(r"^ENV NODE_VERSION ([\d.]+)$", text, re.M)
    if m:
        old = m.group(1)
        major = old.split(".")[0]
        new = node_latest_patch(major)
        if new and vtuple(new) > vtuple(old):
            text = text.replace(f"ENV NODE_VERSION {old}", f"ENV NODE_VERSION {new}", 1)
            lines.append(f"  node    {old} -> {new}")
            changed = True
        elif new:
            lines.append(f"  node    {old} (up to date)")
        if node_is_eol(major):
            lines.append(
                f"  !!      Node {major}.x is past its documented EOL - no further "
                f"upstream patches will ever ship for it; consider retiring this "
                f"directory instead of waiting for a bump"
            )

    m = re.search(r"^ENV YARN_VERSION ([\d.]+)$", text, re.M)
    if m:
        old = m.group(1)
        new = yarn_latest_1x()
        if new and vtuple(new) > vtuple(old):
            text = text.replace(f"ENV YARN_VERSION {old}", f"ENV YARN_VERSION {new}", 1)
            if re.search(r"^ENV YARN_SHA256 [0-9a-f]{64}$", text, re.M):
                new_sha = yarn_sha256(new)
                text = re.sub(
                    r"^ENV YARN_SHA256 [0-9a-f]{64}$",
                    f"ENV YARN_SHA256 {new_sha}",
                    text,
                    count=1,
                    flags=re.M,
                )
            lines.append(f"  yarn    {old} -> {new}")
            changed = True
        elif new:
            lines.append(f"  yarn    {old} (up to date)")

    m = re.search(r"^ENV HELM_VERSION v([\d.]+)$", text, re.M)
    if m:
        old = m.group(1)
        major = old.split(".")[0]
        new = helm_latest(major)
        if new and vtuple(new) > vtuple(old):
            text = text.replace(f"ENV HELM_VERSION v{old}", f"ENV HELM_VERSION v{new}", 1)
            lines.append(f"  helm    v{old} -> v{new}")
            changed = True
        elif new:
            lines.append(f"  helm    v{old} (up to date)")

    m = re.search(r"^ENV AWSCLI_VERSION=([\d.]+)$", text, re.M)
    if m:
        old = m.group(1)
        major = old.split(".")[0]
        new = awscli_latest(major)
        if new and vtuple(new) > vtuple(old):
            text = text.replace(f"ENV AWSCLI_VERSION={old}", f"ENV AWSCLI_VERSION={new}", 1)
            if re.search(r"^ENV AWSCLI_SHA256=[0-9a-f]{64}$", text, re.M):
                new_sha = awscli_sha256(new)
                text = re.sub(
                    r"^ENV AWSCLI_SHA256=[0-9a-f]{64}$",
                    f"ENV AWSCLI_SHA256={new_sha}",
                    text,
                    count=1,
                    flags=re.M,
                )
            lines.append(f"  awscli  {old} -> {new}")
            changed = True
        elif new:
            lines.append(f"  awscli  {old} (up to date)")

    return text, changed


def bump_tags_counter(text):
    """Increment the trailing patch number of the last non-blank TAGS line.

    Mirrors docs/bump-dependabot-image.sh's COUNTER case: silta-cicd TAGS
    files use an independent build counter (e.g. `...-v1.0.2`), unrelated to
    any upstream version, so "bump" just means "+1 patch" to produce a new
    line that .github/workflows/docker-images.yml will notice and build.
    """
    raw_lines = text.splitlines()
    nonblank = [i for i, l in enumerate(raw_lines) if l.strip()]
    if not nonblank:
        return None
    idx = nonblank[-1]
    last = raw_lines[idx]
    m = re.match(r"^(.*-v?)(\d+)\.(\d+)\.(\d+)$", last)
    if not m:
        return None
    prefix, maj, minr, patch = m.groups()
    new_last = f"{prefix}{maj}.{minr}.{int(patch) + 1}"
    raw_lines[idx] = new_last
    return "\n".join(raw_lines) + "\n", last, new_last


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apply", action="store_true", help="write changes to disk (default: dry run)")
    args = parser.parse_args()

    dockerfiles = sorted(CICD_DIR.glob("*/Dockerfile"))
    if not dockerfiles:
        print(f"No Dockerfiles found under {CICD_DIR}", file=sys.stderr)
        return 1

    changed_dirs = 0
    for dockerfile in dockerfiles:
        directory = dockerfile.parent
        lines = []
        text = dockerfile.read_text()
        new_text, changed = bump_dockerfile(text, lines)

        print(f"{directory.name}: {'CHANGED' if changed else 'up to date'}")
        for l in lines:
            print(l)

        if not changed:
            continue

        changed_dirs += 1
        if not args.apply:
            continue

        dockerfile.write_text(new_text)
        tags_file = directory / "TAGS"
        if tags_file.exists():
            result = bump_tags_counter(tags_file.read_text())
            if result:
                new_tags_text, old_last, new_last = result
                tags_file.write_text(new_tags_text)
                print(f"  TAGS    {old_last} -> {new_last}")
            else:
                print(f"  !!      TAGS file has no counter line to bump - release won't auto-trigger")
        else:
            print(f"  !!      no TAGS file at {tags_file} - release won't auto-trigger")

    print()
    if changed_dirs == 0:
        print("All silta-cicd tool pins are up to date.")
    elif args.apply:
        print(f"Applied bumps in {changed_dirs} director{'y' if changed_dirs == 1 else 'ies'}. Review with `git diff` and commit.")
    else:
        print(f"{changed_dirs} director{'y' if changed_dirs == 1 else 'ies'} would change. Rerun with --apply to write changes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
