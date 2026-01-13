FROM alpine:3.23.2

RUN apk add --no-cache --virtual .run-deps "rsync>3.4.0" bash tzdata coreutils && rm -rf /var/cache/apk/*

CMD ["bash"]
