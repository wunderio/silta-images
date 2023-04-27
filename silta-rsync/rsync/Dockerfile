FROM alpine:3.17.3

RUN apk add --no-cache --virtual .run-deps rsync bash tzdata coreutils && rm -rf /var/cache/apk/*

CMD ["bash"]