# https://hub.docker.com/r/cimg/php/tags?name=8.5
FROM cimg/php:8.5.4

# Make composer packages executable.
ENV PATH="/home/circleci/.composer/vendor/bin:/home/circleci/project/vendor/drush/drush:/home/circleci/project/drupal/vendor/drush/drush:${PATH}"

# Upgrade packages
RUN sudo apt update && sudo apt upgrade && sudo apt clean

# Install vim based on popular demand.
RUN sudo apt-get update && sudo apt-get install vim && sudo apt-get clean

# Add gcloud CLI and kubectl
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && sudo apt-get install apt-transport-https ca-certificates gnupg \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
  && sudo apt-get update && sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin kubectl \
  && sudo apt-get clean

# Install AWS cli and aws-iam-authenticator, git, python, pproxy
ENV AWSCLI_VERSION=2.36.46
# sha256 pinned from https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip
ENV AWSCLI_SHA256=835466c6151be2083787734a7ae7c6d23617df94dcd99cbc832879493bcac8f7
RUN sudo apt install -y git python3 python3-pip \
  && sudo apt-get install -y unzip curl \
  && sudo pip3 install pproxy \
  && sudo pip3 install python-daemon \
  && sudo apt remove python3-pip \
  && sudo apt-get clean \
  && sudo curl -f "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o "awscliv2.zip" \
  && echo "${AWSCLI_SHA256}  awscliv2.zip" | sha256sum -c - \
  && sudo unzip awscliv2.zip \
  && sudo ./aws/install \
  && sudo rm -rf awscliv2.zip \
  && sudo rm -rf ./aws

# Install Helm 3
# https://github.com/helm/helm/releases
ENV HELM_VERSION v3.22.0
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL https://get.helm.sh/${FILENAME}

# Helm unit test plugin version.
# https://github.com/helm-unittest/helm-unittest/releases
ENV HELM_UNITTEST_VERSION 1.0.0

RUN curl -fL -o /tmp/$FILENAME ${HELM_URL} \
  && curl -fL -o /tmp/${FILENAME}.sha256sum ${HELM_URL}.sha256sum \
  && (cd /tmp && sha256sum -c ${FILENAME}.sha256sum) \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && rm /tmp/${FILENAME} /tmp/${FILENAME}.sha256sum \
  && sudo mv /tmp/linux-amd64/helm /bin/helm \
  && helm repo add bitnami https://charts.bitnami.com/bitnami \
  # && helm repo add minio https://helm.min.io/ \
  && helm repo add wunderio https://storage.googleapis.com/charts.wdr.io \
  && helm repo add percona https://percona.github.io/percona-helm-charts/ \
  && helm plugin install https://github.com/helm-unittest/helm-unittest --version ${HELM_UNITTEST_VERSION}

# Install Node.js and Yarn.
# The following code is based on the CircleCI Node.js Dockerfile template:
# https://github.com/CircleCI-Public/cimg-shared/blob/main/variants/node.Dockerfile.template
ENV NODE_VERSION 24.21.0
RUN echo "Installing Node.js version ${NODE_VERSION}"
RUN curl -fL -o node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" && \
	curl -fL -o SHASUMS256.txt "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" && \
	echo "$(grep '  node-v'"${NODE_VERSION}"'-linux-x64.tar.xz$' SHASUMS256.txt | awk '{print $1}')  node.tar.xz" | sha256sum -c - && \
	sudo tar -xJf node.tar.xz -C /usr/local --strip-components=1 && \
	rm node.tar.xz SHASUMS256.txt && \
	sudo ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.22.22
# sha256 pinned from https://github.com/yarnpkg/yarn/releases/download/v${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz
ENV YARN_SHA256 88268464199d1611fcf73ce9c0a6c4d44c7d5363682720d8506f6508addf36a0
RUN curl -fL -o yarn.tar.gz "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz" && \
	echo "${YARN_SHA256}  yarn.tar.gz" | sha256sum -c - && \
	sudo tar -xzf yarn.tar.gz -C /opt/ && \
	rm yarn.tar.gz && \
	sudo ln -s /opt/yarn-v${YARN_VERSION}/bin/yarn /usr/local/bin/yarn && \
	sudo ln -s /opt/yarn-v${YARN_VERSION}/bin/yarnpkg /usr/local/bin/yarnpkg

# Add custom php config and lift memory limit.
COPY conf/php/memory.ini /usr/local/etc/php/conf.d/memory.ini
