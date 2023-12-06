# https://docs.robotframework.org/docs/using_rf_in_ci_systems/docker
FROM mcr.microsoft.com/playwright:focal
ARG ROBOTFRAMEWORK_VERSION=6.1.1
USER root
RUN apt-get update
RUN apt-get install -y python3-pip
USER pwuser
RUN pip3 install --user robotframework==${ROBOTFRAMEWORK_VERSION}
RUN pip3 install --user robotframework-browser
RUN ~/.local/bin/rfbrowser init
ENV NODE_PATH=/usr/lib/node_modules
ENV PATH="/home/pwuser/.local/bin:${PATH}"
