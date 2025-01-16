FROM alpine:3.20

RUN apk add --no-cache \
    bash tzdata coreutils \
    nodejs npm
RUN apk add --no-cache 'rsync>~3.4.0'

RUN npm install -g elasticdump@v6 \
    && npm cache clean --force

CMD ["bash"]
