FROM node:18.17-alpine

RUN apk add --no-cache openssh bash rsync curl

EXPOSE 22

RUN mkdir /etc/ssh/keys

# Copy scripts
COPY gitauth_keys.sh /etc/ssh/
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /app

CMD npm run start
