# Proof of concept: node on a Docker Hardened Images base, sibling to
# 22-alpine (official node:22-alpine) for a relaxed rollout - the legacy
# image is left untouched so consumers opt in to this tag deliberately.
# `<major>-alpine-dev` (no pinned alpine/patch version) tracks DHI's floating
# tag so patch releases land without a Dockerfile change.
FROM dhi.io/node:22-alpine-dev

# DHI's apk postinstall trigger that normally creates the `sshd` system user
# does not fire on this minimal base, so openssh-server silently fails to
# bind without it - create it explicitly (uid/gid 22 matches Alpine's own).
RUN apk add --no-cache openssh bash curl tzdata 'rsync>3.4.0' \
  && addgroup -S -g 22 sshd \
  && adduser -S -D -H -h /dev/null -s /sbin/nologin -G sshd -u 22 sshd
EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /
COPY silta /silta

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /app

CMD npm run start
