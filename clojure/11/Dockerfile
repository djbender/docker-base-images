# syntax=docker/dockerfile:1.4

####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:clojure`

########## Clojure image ##########################
FROM ghcr.io/djbender/java:19
LABEL org.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images

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
