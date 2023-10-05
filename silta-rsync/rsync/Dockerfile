FROM alpine:3.18.4

RUN apk add --no-cache --virtual .run-deps rsync bash tzdata coreutils && rm -rf /var/cache/apk/*

CMD ["bash"]