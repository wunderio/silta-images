# https://hg.nginx.org/pkg-oss/tags
ARG NGINX_VERSION=1.21.0

FROM nginx:${NGINX_VERSION}-alpine as builder

# https://github.com/openresty/echo-nginx-module/tags
ENV HTTPECHO_VERSION=0.62

RUN apk add --update gcc libc-dev linux-headers zlib-dev openrc autoconf automake g++ make \
    libressl-dev geoip-dev lmdb-dev pcre-dev libtool libxml2-dev yajl-dev pkgconf zlib-dev \
	libcurl curl

# Download sources
RUN curl "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz && \
  curl -L "https://github.com/openresty/echo-nginx-module/archive/v${HTTPECHO_VERSION}.tar.gz" -o httpecho.tar.gz

# Reuse same cli arguments as the nginx:alpine image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
	# 1.21.x does not compile with -g (Generate debugging information)
    CONFARGS=${CONFARGS/-Os -fomit-frame-pointer -g/-Os} && \
    mkdir /usr/src && \
	tar -zxC /usr/src -f nginx.tar.gz && \
  	# Uncompress echo module
	tar -xzvf "httpecho.tar.gz" && \
  	HTTPECHODIR="$(pwd)/echo-nginx-module-${HTTPECHO_VERSION}" && \
  	cd /usr/src/nginx-$NGINX_VERSION && \
  	./configure --with-compat $CONFARGS --add-dynamic-module=$HTTPECHODIR && \
  	make modules && \
	# Move module to root so it's easier to locate it in the next layer
  	mv ./objs/*.so /

#### Make the nginx image and copy modules from builder

FROM nginx:${NGINX_VERSION}-alpine

LABEL maintainer="wunder.io"

COPY --from=builder /ngx_http_echo_module.so /etc/nginx/modules/ngx_http_echo_module.so
COPY modules/ngx_http_echo.conf /etc/nginx/modules/ngx_http_echo.conf

RUN rm -rf /etc/nginx/conf.d/default.conf

# ensure www-data user exists
# 82 is the standard uid/gid for "www-data" in Alpine
RUN set -x ; \
	addgroup -g 82 -S www-data ; \
	adduser -u 82 -D -S -s /sbin/nologin -G www-data www-data && exit 0 ; exit 1

RUN mkdir -p /var/www/html/web \
      && ln -s /var/www/html /app
