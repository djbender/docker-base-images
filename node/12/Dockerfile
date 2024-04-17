# syntax=docker/dockerfile:1.4


########## Node image ##################
FROM ghcr.io/djbender/core:bionic
LABEL org.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images

USER root
WORKDIR /usr/src/app

ENV NODE_MAJOR 12
ENV NODE_VERSION 12.22.12
ENV NPM_VERSION 6.14.16
ENV YARN_VERSION 1.22.19

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
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_12.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install --yes --no-install-recommends \
    nodejs
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
  npm install --global "npm@${NPM_VERSION}"
  npm install --global "yarn@${YARN_VERSION}"
  rm -rf /root/.npm/_cacache
  npm cache clean --force
  # Check that node commands work
  [ "$(command -v node)" = '/usr/bin/node' ]
  [ "$(command -v npm)" = '/usr/bin/npm' ]
  [ "$(command -v yarn)" = '/usr/bin/yarn' ]
  node -v
  npm -v
  yarn -v
EOT

USER docker
