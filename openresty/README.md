# Openresty docker container for Drupal projects

Openresty base image for Drupal chart hosted on [Silta](https://github.com/wunderio/silta). 

We use [openresty](https://github.com/openresty/openresty/) for `echo_sleep` functionality that allows delaying requests currently. This nginx image serves as a base for the project-specific nginx Dockerfile, and is configured to serve static content and proxy requests to PHP-FPM.