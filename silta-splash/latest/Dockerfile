FROM nginxinc/nginx-unprivileged:1.29.0-alpine-slim

COPY conf/nginx-default.conf /etc/nginx/conf.d/default.conf
COPY src/index.html src/404.html /usr/share/nginx/html/
