# syntax=docker/dockerfile:1.4

# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `rake generate:clojure`

########## Clojure image ##########################
FROM ghcr.io/djbender/java:11
LABEL com.get-bridge.image.authors="get-bridge"
LABEL org.opencontainers.image.source=https://github.com/get-bridge/docker-base-images

USER root

ENV LEIN_VERSION 2.9.1
ENV LEIN_INSTALL /usr/local/bin/
ENV PATH $PATH:$LEIN_INSTALL
ENV LEIN_ROOT 1

RUN <<EOT
#!/usr/bin/env bash
  set -eux

  # install readline library for repl
  apt-get update
  apt-get install --yes --no-install-recommends \
    leiningen \
    rlfe

  [ "$(command -v lein)" = '/usr/bin/lein' ]
  lein --version
EOT

USER docker

WORKDIR /usr/src/app
