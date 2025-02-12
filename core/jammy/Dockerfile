# syntax=docker/dockerfile:1.4

####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:core`

########## core image ##########################
FROM ubuntu:jammy as core
LABEL com.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images
ENV DEBIAN_FRONTEND=noninteractive

# Create a 'docker' user
RUN <<EOT
#!/usr/bin/env bash
set -exu
apt-get update
apt-get install --yes --no-install-recommends \
  ca-certificates \
  locales

# create docker user
addgroup --gid 9999 docker
adduser --uid 9999 --gid 9999 --disabled-password --gecos "Docker User" docker
usermod -L docker

update-ca-certificates
# See the Locals heading at https://hub.docker.com/_/ubuntu
# Alias created as some languages (such as ruby) require the extra local
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
EOT

# Ensure UTF-8 locale
ENV LANG en_US.utf-8
ENV LANGUAGE en_US:en

# Switch to the 'docker' user
USER docker

# keep backwards compatability with use cases that assume CMD is 'bash' since
# specifying an ENTRYPOINT always clears the CMD that was inheritted by the FROM image
# ref: https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
CMD ["bash"]

########## core-dev image ##########################
FROM core as core-dev

# base image starts us with 'docker' user so switch back to root to install packages
USER root

RUN <<EOT
#!/usr/bin/env bash
set -exu
apt-get update
apt-get install --yes --no-install-recommends \
  build-essential \
  git \
  gnupg2 \
  psmisc \
  software-properties-common \
  tzdata

# gnupg2 and dirmngr will attempt to use IPv6 if it's enabled in Docker, even
# if the container doesn't have an IPv6 address (this is true on Docker Hub).
mkdir ~/.gnupg
echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
EOT

# always switch back to docker user
USER docker
