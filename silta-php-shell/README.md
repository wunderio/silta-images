# About project

This image extends the Silta Drupal PHP-FPM image and adds a ssh server configured to allow access based on Github repository access. This is used for Drupal chart deployments hosted on [Silta](https://github.com/wunderio/silta). The key list is provided by [SSH public keys for silta](https://github.com/wunderio/silta-ssh-keys) project.

Fingerprint keys are moved to a dedicated folder, `/etc/ssh/keys`, that can be mounted to a persistent storage.

# Configuration

Provide following environment variables for the container:
 - GITAUTH_URL: Endpoint providing ssh key list. f.ex. https://example.com/api/1/git-ssh-keys
 - GITAUTH_SCOPE: Scope you want to use for authorisation. f.ex. `https://github.com/organisation` or `git@github.com:organisation/reponame.git` for getting public keys of all `reponame` repository collaborators. 
 - GITAUTH_USERNAME: Key server credentials
 - GITAUTH_PASSWORD: Key server credentials
 - OUTSIDE_COLLABORATORS: Include outside collaborators f.ex. "true".

# Running in Docker

Build and run the docker image:
```
docker image build -t ssh-server .
docker run -p 2222:22 --env-file ./env.list -d ssh-server
```

Connect to ssh server
```
ssh www-admin@localhost -p 2222
```
