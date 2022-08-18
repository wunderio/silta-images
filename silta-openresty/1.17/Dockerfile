FROM openresty/openresty:1.17.8.2-alpine

LABEL maintainer="wunder.io"

RUN rm -rf /etc/nginx/conf.d/default.conf

# ensure www-data user exists
# 82 is the standard uid/gid for "www-data" in Alpine
RUN set -x ; \
	addgroup -g 82 -S www-data ; \
	adduser -u 82 -D -S -s /sbin/nologin -G www-data www-data && exit 0 ; exit 1

RUN mkdir -p /var/www/html/web \
      && ln -s /var/www/html /app
