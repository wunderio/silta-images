FROM alpine:3.20.2

RUN apk add --no-cache --virtual .run-deps rsync bash tzdata coreutils && rm -rf /var/cache/apk/*

CMD ["bash"]