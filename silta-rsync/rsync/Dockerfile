FROM alpine:3.21.1

RUN apk add --no-cache --virtual .run-deps rsync bash tzdata coreutils && rm -rf /var/cache/apk/*

CMD ["bash"]