# https://hg.nginx.org/pkg-oss/tags
ARG NGINX_VERSION=1.24.0

FROM nginx:${NGINX_VERSION}-alpine as builder

# https://github.com/openresty/echo-nginx-module/tags
ENV HTTPECHO_VERSION=0.62

# Nginx virtual host traffic status module
# https://github.com/vozlt/nginx-module-vts
ENV NGINX_VTS_VERSION 0.2.2

RUN apk add --update gcc libc-dev linux-headers zlib-dev openrc autoconf automake g++ make \
    libressl-dev geoip-dev lmdb-dev pcre-dev libtool libxml2-dev yajl-dev pkgconf zlib-dev \
	libcurl curl tzdata

# Download sources
RUN curl "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz && \
  curl -L "https://github.com/openresty/echo-nginx-module/archive/v${HTTPECHO_VERSION}.tar.gz" -o httpecho.tar.gz && \
  curl -L "https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v${NGINX_VTS_VERSION}.tar.gz" -o nginx-module-vts.tar.gz

# Reuse same cli arguments as the nginx:alpine image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
	# 1.23.x does not compile with -g (Generate debugging information)
    CONFARGS=${CONFARGS/-Os -fomit-frame-pointer -g/-Os} && \
    mkdir /usr/src && \
	tar -zxC /usr/src -f nginx.tar.gz && \
  	# Uncompress echo module
	tar -xzvf "httpecho.tar.gz" && \
  	HTTPECHODIR="$(pwd)/echo-nginx-module-${HTTPECHO_VERSION}" && \
  	# Uncompress vts module
	tar -xzvf "nginx-module-vts.tar.gz" && \
  	VTSDIR="$(pwd)/nginx-module-vts-${NGINX_VTS_VERSION}" && \
  	cd /usr/src/nginx-$NGINX_VERSION && \
  	./configure --with-compat $CONFARGS \
		--add-dynamic-module=$HTTPECHODIR  \
		--add-dynamic-module=$VTSDIR \
		--with-http_stub_status_module && \
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

# Nginx virtual host traffic status module
COPY --from=builder /ngx_http_vhost_traffic_status_module.so /etc/nginx/modules/ngx_http_vhost_traffic_status_module.so

# Fastly signal sciences module
# https://docs.fastly.com/signalsciences/install-guides/nginx-module/alpine-nginx-1.15.3higher/
RUN apk update && apk add wget openssl --virtual build-dependencies && \
	wget https://apk.signalsciences.net/sigsci_apk.pub ; mv sigsci_apk.pub /etc/apk/keys && \
	echo https://apk.signalsciences.net/3.16/main | tee -a /etc/apk/repositories && \
	apk update && \
	openssl rsa -pubin -in /etc/apk/keys/sigsci_apk.pub -text -noout && \
	apk add nginx-module-sigsci-nxo-${NGINX_VERSION} && \
	apk del build-dependencies
# Module is enabled conditionally via chart template / configmap

RUN rm -rf /etc/nginx/conf.d/default.conf \
		&& touch /var/run/nginx.pid \
		&& chown -R $UID:0 /var/run/nginx.pid

RUN mkdir -p /var/www/html/web \
      && ln -s /var/www/html /app
RUN adduser nginx www-data

STOPSIGNAL SIGQUIT

USER $UID

CMD ["nginx", "-g", "daemon off;"]
