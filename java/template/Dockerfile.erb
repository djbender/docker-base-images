# syntax=<%= docker_syntax %>

<%= generation_message -%>

########## Java image ##########################
FROM <%= base_image %>
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
    openjdk-<%= java_version %>-<%= flavor %>
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*

  # Check that java commands work
  [ "$(command -v java)" = '/usr/bin/java' ]
  java -version
EOT

USER docker

WORKDIR /usr/src/app
