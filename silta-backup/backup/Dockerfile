FROM alpine:3.20

RUN apk add --no-cache \
    bash tzdata coreutils \
    nodejs
RUN apk add --no-cache 'rsync>3.4.0'

RUN apk add --virtual .build-deps npm \
    && npm install -g elasticdump@v6 \
    && npm cache clean --force \
    && apk del .build-deps

CMD ["bash"]
