# Varnish 6.0 LTS, the only supported 6.x line (6.6 is EOL).
FROM varnish:6.0.18

ARG VARNISH_STORAGE_BACKEND
ARG VARNISH_EXTRA_PARAMS

EXPOSE 80 6082

COPY secret /etc/varnish/secret
COPY varnish-start.sh /

RUN mkdir -p -m a+w /var/lib/varnish/

COPY TAGS /TAGS

CMD ["/varnish-start.sh"]
