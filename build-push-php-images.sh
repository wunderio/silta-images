#!/bin/bash

# Build and push fpm and shell test images 

docker build --tag wunderio/silta-php-fpm:test-7.2 silta-php-fpm/7.2-fpm
docker build --tag wunderio/silta-php-fpm:test-7.3 silta-php-fpm/7.3-fpm
docker build --tag wunderio/silta-php-fpm:test-7.4 silta-php-fpm/7.4-fpm
docker build --tag wunderio/silta-php-fpm:test-8.0 silta-php-fpm/8.0-fpm
docker build --tag wunderio/silta-php-fpm:test-8.1 silta-php-fpm/8.1-fpm

docker push wunderio/silta-php-fpm:test-7.2
docker push wunderio/silta-php-fpm:test-7.3
docker push wunderio/silta-php-fpm:test-7.4
docker push wunderio/silta-php-fpm:test-8.0
docker push wunderio/silta-php-fpm:test-8.1

docker build --tag wunderio/silta-php-shell:test-7.2 silta-php-shell/php-7.2
docker build --tag wunderio/silta-php-shell:test-7.3 silta-php-shell/php-7.3
docker build --tag wunderio/silta-php-shell:test-7.4 silta-php-shell/php-7.4
docker build --tag wunderio/silta-php-shell:test-8.0 silta-php-shell/php-8.0
docker build --tag wunderio/silta-php-shell:test-8.1 silta-php-shell/php-8.1

docker push wunderio/silta-php-shell:test-7.2
docker push wunderio/silta-php-shell:test-7.3
docker push wunderio/silta-php-shell:test-7.4
docker push wunderio/silta-php-shell:test-8.0
docker push wunderio/silta-php-shell:test-8.1

# Build and push shell images

# docker build --tag wunderio/silta-php-shell:php7.2-v0.1 --tag eu.gcr.io/silta-images/shell:php7.2-v0.1 silta-php-shell/php-7.2
# docker build --tag wunderio/silta-php-shell:php7.3-v0.1 --tag eu.gcr.io/silta-images/shell:php7.3-v0.1 silta-php-shell/php-7.3
# docker build --tag wunderio/silta-php-shell:php7.4-v0.1 --tag eu.gcr.io/silta-images/shell:php7.4-v0.1 silta-php-shell/php-7.4
# docker build --tag wunderio/silta-php-shell:php8.0-v0.1 --tag eu.gcr.io/silta-images/shell:php8.0-v0.1 silta-php-shell/php-8.0
# docker build --tag wunderio/silta-php-shell:php8.1-v0.1 --tag eu.gcr.io/silta-images/shell:php8.1-v0.1 silta-php-shell/php-8.1

# docker push wunderio/silta-php-shell:php7.2-v0.1
# docker push wunderio/silta-php-shell:php7.3-v0.1
# docker push wunderio/silta-php-shell:php7.4-v0.1
# docker push wunderio/silta-php-shell:php8.0-v0.1
# docker push wunderio/silta-php-shell:php8.1-v0.1

# docker push eu.gcr.io/silta-images/shell:php7.2-v0.1 
# docker push eu.gcr.io/silta-images/shell:php7.3-v0.1 
# docker push eu.gcr.io/silta-images/shell:php7.4-v0.1 
# docker push eu.gcr.io/silta-images/shell:php8.0-v0.1 
# docker push eu.gcr.io/silta-images/shell:php8.1-v0.1 
