FROM alpine:3.22.2

RUN apk add --no-cache \
    bash tzdata coreutils \
    nodejs 'rsync>3.4.0'

RUN apk add --no-cache --virtual .build-deps npm \
    && npm install -g elasticdump@v6 \
    && npm cache clean --force \
    && apk del .build-deps

CMD ["bash"]
