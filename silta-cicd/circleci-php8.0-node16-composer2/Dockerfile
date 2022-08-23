FROM cimg/php:8.0.13-node

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
ENV GCLOUD_VERSION 392.0.0-0
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && sudo apt-get install apt-transport-https ca-certificates \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && sudo apt-get update && sudo apt-get install google-cloud-sdk=${GCLOUD_VERSION} google-cloud-sdk-gke-gcloud-auth-plugin kubectl \
  && gcloud --version \
  && sudo apt-get clean

# Install AWS cli and aws-iam-authenticator
RUN sudo apt install -y awscli git python3 \
  && curl -o /tmp/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator \
  && chmod +x /tmp/aws-iam-authenticator \ 
  && sudo mv /tmp/aws-iam-authenticator /bin/aws-iam-authenticator

# Install Azure cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Helm 3
ENV HELM_VERSION v3.6.3
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL https://get.helm.sh/${FILENAME}

# Clean up
RUN sudo apt-get clean autoclean -y \
  && sudo apt-get autoremove -y \
  && sudo rm -rf /var/lib/apt \
    /var/lib/dpkg  \
    /var/lib/cache \
    /var/lib/log \
    /var/tmp/* \
    /usr/share/doc/ /usr/share/man/ /usr/share/locale/ \
		/root/.cache /root/.local /root/.gnupg /root/.config \
    /tmp/*
  && sudo touch /var/lib/dpkg/status \
  && sudo mkdir /var/lib/dpkg/updates /var/lib/dpkg/info
  && sudo sudo mkdir -p /var/lib/dpkg/{updates,alternatives,info,parts,triggers}

# NOTE: quintush/helm-unittest v0.2.0 release breaks helm tests.

# TODO: when https://github.com/lrills/helm-unittest/issues/87 is merged,
# switch back to using https://github.com/lrills/helm-unittest as the source

# Clean up
RUN sudo apt-get clean autoclean -y \
  && sudo apt-get autoremove -y \
  && sudo rm -rf /var/lib/apt \
    /var/lib/dpkg  \
    /var/lib/cache \
    /var/lib/log \
    /var/tmp/* \
    /usr/share/doc/ /usr/share/man/ /usr/share/locale/ \
		/root/.cache /root/.local /root/.gnupg /root/.config \
    /tmp/*
  && sudo touch /var/lib/dpkg/status \
  && sudo mkdir /var/lib/dpkg/updates /var/lib/dpkg/info
  && sudo sudo mkdir -p /var/lib/dpkg/{updates,alternatives,info,parts,triggers}

# Add custom php config and lift memory limit.
COPY conf/php/memory.ini /usr/local/etc/php/conf.d/memory.ini
