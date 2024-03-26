FROM alpine:3.19

RUN apk add --no-cache --virtual .run-deps \
    bash tzdata coreutils \
    rsync \
    npm nodejs

RUN npm install -g elasticdump@v6

# Clean up
RUN rm -rf /var/cache/apk/*

CMD ["bash"]