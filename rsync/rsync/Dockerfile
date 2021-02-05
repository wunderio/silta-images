FROM alpine:3

RUN apk add --no-cache --virtual .run-deps rsync tzdata && rm -rf /var/cache/apk/*

CMD ["sh"]