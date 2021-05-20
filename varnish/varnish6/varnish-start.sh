#!/bin/sh
/usr/sbin/varnishd -F -f /etc/varnish/default.vcl -T :6082 -S /etc/varnish/secret -s ${VARNISH_STORAGE_BACKEND:-'file,/var/lib/varnish/varnish_storage.bin,512M'} ${VARNISH_EXTRA_PARAMS}
