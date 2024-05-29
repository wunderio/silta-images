FROM cimg/php:8.1.7

# Make composer packages executable.
ENV PATH="/home/circleci/.composer/vendor/bin:${PATH}"

# Upgrade packages
RUN sudo apt update && sudo apt upgrade && sudo apt clean

# Install drush
ENV DRUSH_LAUNCHER_VERSION 0.9.1
RUN sudo wget -q https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar -O /usr/local/bin/drush \
  && sudo chmod +x /usr/local/bin/drush

# Install vim based on popular demand.
RUN sudo apt-get update && sudo apt-get install vim && sudo apt-get clean

# Add gcloud CLI and kubectl
ENV GCLOUD_VERSION 348.0.0-0
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
ENV HELM_VERSION v3.14.0
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
  && helm plugin install https://github.com/quintush/helm-unittest --version 0.2.4

# NOTE: quintush/helm-unittest v0.2.0 release breaks helm tests.

# TODO: when https://github.com/lrills/helm-unittest/issues/87 is merged,
# switch back to using https://github.com/lrills/helm-unittest as the source

# Install Node.js and Yarn.
# The following code is based on the CircleCI Node.js Dockerfile template:
# https://github.com/CircleCI-Public/cimg-shared/blob/main/variants/node.Dockerfile.template
ENV NODE_VERSION 16.15.1
RUN echo "Installing Node.js version ${NODE_VERSION}"
RUN curl -L -o node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" && \
	sudo tar -xJf node.tar.xz -C /usr/local --strip-components=1 && \
	rm node.tar.xz && \
	sudo ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.22.5
RUN curl -L -o yarn.tar.gz "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz" && \
	sudo tar -xzf yarn.tar.gz -C /opt/ && \
	rm yarn.tar.gz && \
	sudo ln -s /opt/yarn-v${YARN_VERSION}/bin/yarn /usr/local/bin/yarn && \
	sudo ln -s /opt/yarn-v${YARN_VERSION}/bin/yarnpkg /usr/local/bin/yarnpkg \

# Add custom php config and lift memory limit.
COPY conf/php/memory.ini /usr/local/etc/php/conf.d/memory.ini
