FROM varnish:6.0

ARG VARNISH_STORAGE_BACKEND
ARG VARNISH_EXTRA_PARAMS

EXPOSE 80 6082

COPY secret /etc/varnish/secret
COPY varnish-start.sh /

RUN mkdir -p -m a+w /var/lib/varnish/

CMD ["/varnish-start.sh"]