FROM php:8.0.13-cli-alpine
LABEL maintainer="wunder.io"

# This file is generated from template. Do not edit it.

# PHP package manager Composer
ENV PHP_COMPOSER_VERSION 2.1.12
# ENV PHP_COMPOSER_VERSION 2.1.12

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
	php composer-setup.php --version=$PHP_COMPOSER_VERSION --install-dir=/usr/local/bin --filename=composer && \
	php -r "unlink('composer-setup.php');" && \
	composer --version

ENV PATH /home/circleci/.config/composer/vendor/bin:/home/circleci/.composer/vendor/bin:$PATH


# CircleCi base
# https://github.com/CircleCI-Public/cimg-base/blob/main/22.04/Dockerfile

# ENV TERM=dumb \
#     PAGER=cat

RUN apk update && apk add --no-cache bash sudo && \
  addgroup -S circleci && \
  adduser \
    --disabled-password \
    --gecos "" \
    --home /home/circleci \
    --ingroup circleci \
    --uid=3434 \
    --shell=/bin/bash \
    circleci

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN echo 'circleci ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-circleci && \
    echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep && \
    sudo -u circleci mkdir /home/circleci/project && \
    sudo -u circleci mkdir /home/circleci/bin && \
    # Install Dockerize v0.6.1
    # Source repo: https://github.com/jwilder/dockerize
    # I (Ricardo) would like to replace this one day. It's a tool not really
    # maintained and we can likely offer something better.
    curl -sSL --fail --retry 3 --output /tmp/dockerize-linux-amd64.tar.gz "https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/dockerize-latest.tar.gz" && \
    tar -C /usr/local/bin -xzvf /tmp/dockerize-linux-amd64.tar.gz && \
    rm -rf /tmp/dockerize-linux-amd64.tar.gz && \
    # Quick test of Dockerize
    dockerize --version && \
    apk add --no-cache \
      autoconf \
      # build-essential \
      ca-certificates \
      cmake \
      # already installed but here for consistency
      curl \
      gnupg \
      gzip \
      jq \
      # libcurl4-openssl-dev \
      curl-dev \
      # popular DB lib - MariaDB
      # libmariadb-dev \
      mariadb-dev \
      # allows MySQL users to use MariaDB lib
      # libmariadb-dev-compat \
      # popular DB lib - PostgreSQL
      libpq-dev \
      # libssl-dev \
      openssl-dev \
      # libsqlite3-dev \
      sqlite-dev \
      make \
      # for ssh-enabled builds
      nano \
      net-tools \
      # netcat \
      netcat-openbsd \
      openssh-client \
      parallel \
      # compiling tool
      # pkg-config \
      pkgconfig \
      postgresql-client \
      shellcheck \
      # software-properties-common \
      # already installed but here for consistency
      sudo \
      tar \
      tzdata \
      unzip \
      # for ssh-enabled builds
      vim \
      wget \
      zip \
      git \
      procps

RUN apk add --update docker && \
  docker --version

# I don't think this works
#ENV COMPOSE_VER 2.6.0
ENV COMPOSE_SWITCH_VERSION 1.0.4

RUN apk add --no-cache docker-compose docker-cli-compose && \
	curl -fL https://github.com/docker/compose-switch/releases/download/v${COMPOSE_SWITCH_VERSION}/docker-compose-linux-amd64 -o /usr/local/bin/compose-switch && \
	# Quick test of the Docker Compose install
	docker compose version && \
	chmod +x /usr/local/bin/compose-switch && \
  # update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/compose-switch 99 && \
	mv /usr/bin/docker-compose /usr/bin/docker-compose_original && \
	ln -s /usr/local/bin/compose-switch /usr/local/bin/docker-compose && \
  # Tests if docker-compose for v1 is transposed to v2
	docker-compose version

RUN curl -sSL "https://github.com/mikefarah/yq/releases/download/v4.23.1/yq_linux_amd64.tar.gz" | \
	tar -xz -C /usr/local/bin && \
	# mv /usr/local/bin/yq{_linux_amd64,}
	mv /usr/local/bin/yq_linux_amd64 /usr/local/bin/yq
USER circleci
# Run commands and tests as circleci user
RUN whoami && \
	# opt-out of the new security feature, not needed in a CI environment
	git config --global --add safe.directory '*'

# Match the default CircleCI working directory
WORKDIR /home/circleci/project


# CI tooling
ENV DRUSH_LAUNCHER_VERSION 0.9.1
ENV AZURE_CLI_VERSION 2.0.61
ENV CLOUD_SDK_VERSION 392.0.0
ENV KUBECTL_VERSION 1.24.0
ENV HELM_VERSION v3.6.3
ENV PATH="/home/circleci/bin:/home/circleci/.local/bin:/home/circleci/.composer/vendor/bin:${PATH}" \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# Install drush launcher
# ENV DRUSH_LAUNCHER_VERSION 0.9.1
RUN sudo wget -q https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar -O /usr/local/bin/drush \
  && sudo chmod +x /usr/local/bin/drush

# Add gcloud CLI
# ENV CLOUD_SDK_VERSION 392.0.0
ENV ARCH x86_64
ENV PATH="/home/circleci/google-cloud-sdk/bin:${PATH}"
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True

RUN sudo apk --no-cache add curl python3 py3-crcmod py3-openssl bash libc6-compat openssh-client git gnupg && \
  curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
  tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz --directory /home/circleci && \
  rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
  gcloud config set core/disable_usage_reporting true && \
  gcloud config set component_manager/disable_update_check true && \
  gcloud config set metrics/environment github_docker_image && \
  gcloud --version && \
  gcloud components install gke-gcloud-auth-plugin

# Install AWS cli and aws-iam-authenticator
RUN sudo apk add --no-cache aws-cli && \
  curl -o /tmp/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator && \
  chmod +x /tmp/aws-iam-authenticator && \ 
  sudo mv /tmp/aws-iam-authenticator /bin/aws-iam-authenticator

# Install Azure cli
# ENV AZURE_CLI_VERSION 2.0.61
RUN sudo apk add bash py-pip && \
  sudo apk add --virtual=build gcc python3-dev musl-dev libffi-dev openssl-dev make  && \
  pip3 --no-cache-dir install azure-mgmt-resource azure-cli==${AZURE_CLI_VERSION} && \
  sudo apk del --purge build && \
  sudo ln -s /usr/bin/python3 /usr/bin/python && \
  az --version

# Kubectl
# ENV KUBECTL_VERSION 1.24.0
RUN sudo wget -q https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
  && sudo chmod +x /usr/local/bin/kubectl

# Install Helm 3
# ENV HELM_VERSION v3.6.3
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL https://get.helm.sh/${FILENAME}

RUN curl -o /tmp/$FILENAME ${HELM_URL} \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && rm /tmp/${FILENAME} \
  && sudo mv /tmp/linux-amd64/helm /bin/helm \
  && helm repo add bitnami https://charts.bitnami.com/bitnami \
  && helm repo add minio https://helm.min.io/ \
  && helm repo add wunderio https://storage.googleapis.com/charts.wdr.io \
  && helm repo add percona https://percona.github.io/percona-helm-charts/ \
  && helm plugin install https://github.com/quintush/helm-unittest --version 0.2.4

# NOTE: quintush/helm-unittest v0.2.0 release breaks helm tests.

# TODO: when https://github.com/lrills/helm-unittest/issues/87 is merged,
# switch back to using https://github.com/lrills/helm-unittest as the source

# TODO: Add custom php config and lift memory limit.
COPY conf/php/memory.ini /usr/local/etc/php/conf.d/memory.ini


# NodeJS and Yarn
ENV NODE_VERSION 16.15.1
ENV YARN_VERSION 1.22.19
# https://github.com/nodejs/docker-node/blob/194a775693fd40598a1bafd4858e063c24efeb42/16/alpine3.15/Dockerfile

RUN sudo apk add --no-cache \
        libstdc++ \
    && sudo apk add --no-cache --virtual .build-deps \
        curl \
    && ARCH= && alpineArch="$(apk --print-arch)" \
      && case "${alpineArch##*-}" in \
        x86_64) \
          ARCH='x64' \
          CHECKSUM="3acef00c21ca044a74710a56492c40d715ea5a707ce8629d6df2415f3cf89fec" \
          ;; \
        *) ;; \
      esac \
  && if [ -n "${CHECKSUM}" ]; then \
    set -eu; \
    curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz"; \
    echo "$CHECKSUM  node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" | sha256sum -c - \
      && sudo tar -xJf "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
      && sudo ln -s /usr/local/bin/node /usr/local/bin/nodejs; \
  else \
    echo "Building from source" \
    # backup build
    && sudo apk add --no-cache --virtual .build-deps-full \
        binutils-gold \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python3 \
    # gpg keys listed at https://github.com/nodejs/node#release-keys
    && for key in \
      4ED778F539E3634C779C87C6D7062848A1AB005C \
      141F07595B7B3FFE74309A937405533BE57C7D57 \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      74F12602B6F1C4E913FAA37AD3A89613643B6201 \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      61FC681DFB92A079F1685E77973F295594EC4689 \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
      C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
      108F52B48DB57BB0CC439B2997B01419BD92F80A \
      B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) V= \
    && sudo make install \
    && sudo apk del .build-deps-full \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt; \
  fi \
  && rm -f "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" \
  && sudo apk del .build-deps \
  # smoke tests
  && node --version \
  && npm --version


RUN sudo apk add --no-cache --virtual .build-deps-yarn curl gnupg tar \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && sudo mkdir -p /opt \
  && sudo tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && sudo ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && sudo ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && sudo apk del .build-deps-yarn \
  # smoke test
  && yarn --version

