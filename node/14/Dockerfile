# syntax=docker/dockerfile:1.4


########## node image ##################
FROM ghcr.io/djbender/core:jammy AS node
LABEL org.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images

USER root
WORKDIR /usr/src/app

ENV NODE_MAJOR=14
ENV NODE_VERSION=14.21.3
ENV NPM_VERSION=6.14.18
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

  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | apt-key add -
  echo "deb https://deb.nodesource.com/node_14.x jammy main" \
    > /etc/apt/sources.list.d/nodesource.list

  apt-get update
  echo "Now checking that upstream version matches what we expect before continuing..."
  REPO_VERSION=$(apt-cache policy nodejs | grep Candidate | awk '{print $2}' | cut -d'+' -f1 | cut -d'-' -f1)
  if [ "${REPO_VERSION}" = "${NODE_VERSION}" ]; then
    echo "Versions match!"
  else
    echo "[ERROR]: Versions did not match!"
    exit 1
  fi
  apt-get install --yes --no-install-recommends \
    nodejs
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

  npm install --global "yarn@${YARN_VERSION}"
  rm -rf /root/.npm/_cacache
  npm cache clean --force

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
