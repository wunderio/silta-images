FROM alpine

RUN apk add tinyproxy

# Allow all sources, this needs to be update.
RUN sed -i "s/^Allow/#Allow/" /etc/tinyproxy/tinyproxy.conf

# Use port 80 by default
RUN sed -i "s/8888/80/" /etc/tinyproxy/tinyproxy.conf

CMD tinyproxy -d