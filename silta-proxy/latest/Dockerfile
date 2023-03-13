FROM alpine:3.17.2

ARG PROXY_MAXCLIENTS=5000
ARG PROXY_PORT=80

RUN apk add tinyproxy

RUN sed -i "s/^Allow/#Allow/" /etc/tinyproxy/tinyproxy.conf \
  # Use port 80 by default
  && sed -i "s/8888/${PROXY_PORT}/" /etc/tinyproxy/tinyproxy.conf \
  # Increase connections 
  && sed -i "s/MaxClients 100/MaxClients ${PROXY_MAXCLIENTS}/" /etc/tinyproxy/tinyproxy.conf 

CMD tinyproxy -d