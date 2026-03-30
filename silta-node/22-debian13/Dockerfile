# Migrated from node:22.22.1-alpine to DHI debian13-dev variant.
# DHI -dev variant used because entrypoint requires bash, sshd, and system tools.
FROM dhi.io/node:22-debian13-dev

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    openssh-client \
    bash \
    rsync \
    curl \
    tzdata \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /run/sshd

EXPOSE 22

RUN mkdir -p /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /
COPY silta /silta

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /app

CMD ["npm", "run", "start"]
