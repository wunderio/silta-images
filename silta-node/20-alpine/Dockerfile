FROM node:20.20.2-alpine

# Pull in security fixes for packages shipped with the base image
RUN apk upgrade --no-cache

# Require openssh with the password authentication bypass fix (Alpine advisory 2026-11-05)
RUN apk add --no-cache 'openssh>=10.2_p1-r1' 'openssh-server>=10.2_p1-r1' bash 'rsync>3.4.0' curl tzdata

EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /
COPY silta /silta

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /app

CMD npm run start
