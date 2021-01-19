FROM circleci/php:8.0.1-cli-node

# Make composer packages executable.
ENV PATH="/home/circleci/.composer/vendor/bin:${PATH}"

# Install drush
RUN composer global require drush/drush-launcher \
  && composer clearcache

# Install vim based on popular demand.
RUN sudo apt-get update && sudo apt-get install vim && sudo apt-get clean

# Add gcloud CLI and kubectl
ENV GCLOUD_VERSION 291.0.0-0
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && sudo apt-get install apt-transport-https ca-certificates \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && sudo apt-get update && sudo apt-get install google-cloud-sdk=${GCLOUD_VERSION} kubectl \
  && sudo apt-get clean

# Install Helm 3
ENV HELM_VERSION v3.2.4
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL https://get.helm.sh/${FILENAME}

RUN curl -o /tmp/$FILENAME ${HELM_URL} \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && rm /tmp/${FILENAME} \
  && sudo mv /tmp/linux-amd64/helm /bin/helm \
#  && helm repo add stable https://kubernetes-charts.storage.googleapis.com/ \
  && helm repo add bitnami https://charts.bitnami.com/bitnami \
  && helm repo add minio https://helm.min.io/ \
  && helm repo add wunderio https://storage.googleapis.com/charts.wdr.io \
  && helm plugin install https://github.com/quintush/helm-unittest --version 0.2.4

# NOTE: quintush/helm-unittest v0.2.0 release breaks helm tests.

# TODO: when https://github.com/lrills/helm-unittest/issues/87 is merged,
# switch back to using https://github.com/lrills/helm-unittest as the source

# Add custom php config and lift memory limit.
COPY conf/php/memory.ini /usr/local/etc/php/conf.d/memory.ini
