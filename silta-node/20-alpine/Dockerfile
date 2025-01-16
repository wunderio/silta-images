FROM node:20.18.1-alpine

RUN apk add --no-cache openssh bash 'rsync>3.4.0' curl tzdata

EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /
COPY silta /silta

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /app

CMD npm run start
