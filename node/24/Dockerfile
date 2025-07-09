# syntax=docker/dockerfile:1.4


########## node image ##################
FROM ghcr.io/djbender/core AS node
LABEL org.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images

USER root
WORKDIR /usr/src/app

ENV NODE_MAJOR=24
ENV NODE_VERSION=24.4.0
ENV NPM_VERSION=11.4.2
ENV YARN_VERSION=1.22.22

RUN <<EOT
#/usr/bin/env bash
  set -exu
  mkdir -p /usr/src/app
  chown docker:docker /usr/src/app
  apt-get update
  apt-get install --yes --no-install-recommends \
    apt-transport-https \
    curl \
    gnupg

  mkdir -p /usr/share/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

  apt-get update
  apt-get install --yes --no-install-recommends \
    nodejs
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

  corepack enable

  # Check that node commands work
  [ "$(command -v node)" = '/usr/bin/node' ]
  [ "$(command -v npm)" = '/usr/bin/npm' ]
  [ "$(command -v yarn)" = '/usr/bin/yarn' ]
  [ "$(node -v)" = "v${NODE_VERSION}" ]
  [ "$(npm -v)" = "${NPM_VERSION}" ]
  [ "$(yarn -v)" = "${YARN_VERSION}" ]
EOT

USER docker

########## node-dev image ##################
FROM node AS node-dev

USER root
RUN <<EOT
#/usr/bin/env bash
  apt-get update
  apt-get install --yes --no-install-recommends \
    build-essential
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

USER docker
