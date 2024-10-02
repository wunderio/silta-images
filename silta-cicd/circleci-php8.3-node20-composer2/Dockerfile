FROM cimg/php:8.3.12-node

# Make composer packages executable.
ENV PATH="/home/circleci/.composer/vendor/bin:${PATH}"

# Upgrade packages
RUN sudo apt update && sudo apt upgrade && sudo apt clean

# Install drush
ENV DRUSH_LAUNCHER_VERSION 0.10.2
RUN sudo wget -q https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar -O /usr/local/bin/drush \
  && sudo chmod +x /usr/local/bin/drush

# Install vim based on popular demand.
RUN sudo apt-get update && sudo apt-get install vim && sudo apt-get clean

# Add gcloud CLI and kubectl
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && sudo apt-get install apt-transport-https ca-certificates \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && sudo apt-get update && sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin kubectl \
  && sudo apt-get clean

# Install AWS cli and aws-iam-authenticator, git, python
RUN sudo apt install -y git python3 \
  && sudo apt-get install -y unzip curl \
  && sudo apt-get clean \
  && sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && sudo  unzip awscliv2.zip \
  && sudo ./aws/install \
  && sudo  rm -rf awscliv2.zip \
  && sudo  rm -rf ./aws

# Install Helm 3
ENV HELM_VERSION v3.14.3
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL https://get.helm.sh/${FILENAME}

RUN curl -o /tmp/$FILENAME ${HELM_URL} \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && rm /tmp/${FILENAME} \
  && sudo mv /tmp/linux-amd64/helm /bin/helm \
  && helm repo add bitnami https://charts.bitnami.com/bitnami \
  # && helm repo add minio https://helm.min.io/ \
  && helm repo add wunderio https://storage.googleapis.com/charts.wdr.io \
  && helm repo add percona https://percona.github.io/percona-helm-charts/ \
  && helm plugin install https://github.com/helm-unittest/helm-unittest --version 0.4.3

# Add custom php config and lift memory limit.
COPY conf/php/memory.ini /usr/local/etc/php/conf.d/memory.ini
