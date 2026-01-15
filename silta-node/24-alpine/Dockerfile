# https://hub.docker.com/_/node/tags?name=24.
FROM node:24.13.0-alpine

RUN apk add --no-cache openssh bash curl tzdata 'rsync>3.4.0'
EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /
COPY silta /silta

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /app

CMD npm run start
