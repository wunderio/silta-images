# https://hg.nginx.org/pkg-oss/tags
ARG NGINX_VERSION=1.17.10

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
    CONFARGS=${CONFARGS/-Os -fomit-frame-pointer/-Os} && \
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

FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}-alpine
ARG UID=101
LABEL maintainer="wunder.io"
USER root

COPY --from=builder /ngx_http_echo_module.so /etc/nginx/modules/ngx_http_echo_module.so
COPY modules/ngx_http_echo.conf /etc/nginx/modules/ngx_http_echo.conf

RUN rm -rf /etc/nginx/conf.d/default.conf

RUN rm -rf /etc/nginx/conf.d/default.conf \
		&& touch /var/run/nginx.pid \
		&& chown -R $UID:0 /var/run/nginx.pid

RUN mkdir -p /var/www/html/web \
      && ln -s /var/www/html /app
RUN adduser nginx www-data

USER $UID

CMD ["nginx", "-g", "daemon off;"]
