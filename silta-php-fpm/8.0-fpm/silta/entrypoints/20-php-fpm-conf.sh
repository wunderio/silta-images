#!/usr/bin/env sh

# Copy customized php-fpm configuration
if [ -f /tmp/zz-custom.conf ]; then
  cp /tmp/zz-custom.conf /usr/local/etc/php-fpm.d/zz-custom.conf
fi
