FROM alpine:3.21

RUN apk add --no-cache \
    bash tzdata coreutils \
    rsync \
    nodejs

RUN apk add --no-cache --virtual .build-deps npm \
    && npm install -g elasticdump@v6 \
    && npm cache clean --force \
    && apk del .build-deps

CMD ["bash"]