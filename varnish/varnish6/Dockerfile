FROM varnish:6.0

ARG VARNISH_STORAGE_BACKEND

EXPOSE 80 6082

COPY secret /etc/varnish/secret
COPY varnish-start.sh /

CMD ["/varnish-start.sh"]