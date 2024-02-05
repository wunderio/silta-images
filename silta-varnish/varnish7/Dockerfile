FROM varnish:7.4.2-alpine

ARG VARNISH_STORAGE_BACKEND
ARG VARNISH_EXTRA_PARAMS

EXPOSE 8080 6082

COPY secret /etc/varnish/secret
COPY varnish-start.sh /

USER root

RUN mkdir -p -m a+w /var/lib/varnish/ \
    && chown varnish /var/lib/varnish

COPY TAGS /TAGS

USER varnish

CMD ["/varnish-start.sh"]