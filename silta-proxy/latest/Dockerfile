FROM alpine

RUN apk add tinyproxy

RUN sed -i "s/^Allow/#Allow/" /etc/tinyproxy/tinyproxy.conf \
  # Use port 80 by default
  && sed -i "s/8888/80/" /etc/tinyproxy/tinyproxy.conf \
  # Increase connections 
  && sed -i "s/MaxClients 100/MaxClients 1000/" /etc/tinyproxy/tinyproxy.conf 

CMD tinyproxy -d