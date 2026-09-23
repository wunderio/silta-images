## What it does

For every `silta-cicd/*/Dockerfile`, it checks each pinned tool against upstream.
Bumps `NODE_VERSION` / `YARN_VERSION` / `HELM_VERSION` / `AWSCLI_VERSION` to the latest release  
**within the same major line already pinned**

## Usage

```sh
# Dry run - report only, touches nothing
automation/bump-cicd-tool-versions.py

# Write the bumps to disk (Dockerfile + TAGS)
automation/bump-cicd-tool-versions.py --apply
```
