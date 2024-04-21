# syntax=docker/dockerfile:1.4

# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `rake generate:core-dev`

########## Core image ##########################
FROM ghcr.io/djbender/core:jammy
LABEL com.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images
ENV DEBIAN_FRONTEND=noninteractive

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
