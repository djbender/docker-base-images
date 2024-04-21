# syntax=<%= docker_syntax %>

<%= generation_message -%>

########## Clojure image ##########################
FROM <%= base_image %>:<%= java_version %>
LABEL com.get-bridge.image.authors="get-bridge"
LABEL org.opencontainers.image.source=https://github.com/get-bridge/docker-base-images

USER root

ENV LEIN_VERSION <%= lein_version %>
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
