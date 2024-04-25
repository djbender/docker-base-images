# syntax=docker/dockerfile:1.4

####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:java`

########## Java image ##########################
FROM ghcr.io/djbender/core
LABEL com.get-bridge.image.authors="get-bridge"
LABEL org.opencontainers.image.source=https://github.com/get-bridge/docker-base-images

USER root

RUN <<EOT
#!/usr/bin/env bash
  set -eux
  mkdir -p /usr/src/app
  chown docker:docker /usr/src/app
  apt-get update
  apt-get install --yes --no-install-recommends \
    openjdk-18-jre
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*

  # Check that java commands work
  [ "$(command -v java)" = '/usr/bin/java' ]
  java -version
EOT

USER docker

WORKDIR /usr/src/app
