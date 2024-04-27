# syntax=docker/dockerfile:1.4

##################################################################
### Gems build container
##################################################################
FROM ghcr.io/djbender/ruby:2.7-dev AS gem_builder

ENV POSTGRESQL_VERSION 11
ENV APP_USER=docker

USER root
# Install packages
RUN <<EOT
#!/usr/bin/env bash
  apt update
  apt install -y --no-install-recommends curl lsb-release
  curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list
  apt update
  apt install -y --no-install-recommends libxmlsec1-dev libjemalloc2 automake \
    git build-essential patch zlib1g-dev liblzma-dev libpq-dev postgresql-client-$POSTGRESQL_VERSION \
    libcurl4-openssl-dev libsqlite3-dev shared-mime-info
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/ /var/cache/* || true
EOF

ENV LD_PRELOAD libjemalloc.so.2

# Switch to the docker user
USER $APP_USER

# Create app directory and install gems
COPY --chown=$APP_USER:$APP_USER Gemfile Gemfile.lock ./

RUN <<EOT
#!/usr/bin/env bash
  bundle config build.puma "--with-cflags='-D PUMA_QUERY_STRING_MAX_LENGTH=64000'"
  bundle install --jobs "$(nproc)"
  rm -rf $GEM_HOME/cache/*.gem
  find $GEM_HOME/gems/ -name "*.c" -delete
  find $GEM_HOME/gems/ -name "*.o" -delete
EOF


##################################################################
### Deploy container
##################################################################
FROM ghcr.io/djbender/ruby:2.7 AS deploy

ENV POSTGRESQL_VERSION 11

# Use the docker user.... jk we have to run as root until we figure out how to assume
# a role with the container without being root.
ENV APP_USER=root

# Copy over installed gems
COPY --from=gem_builder $GEM_HOME $GEM_HOME

RUN <<EOT
#!/usr/bin/env bash
  apt update
  apt install -y --no-install-recommends curl lsb-release
  curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list
  apt update
  apt install -y --no-install-recommends libxmlsec1-dev libjemalloc2 automake \
    git build-essential patch zlib1g-dev liblzma-dev libpq-dev postgresql-client-$POSTGRESQL_VERSION \
    libcurl4-openssl-dev libsqlite3-dev shared-mime-info ffmpeg
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/ /var/cache/* || true
EOF


# Create additional directories your project may need
# remember WORKDIR is /usr/src/app
ENV LD_PRELOAD libjemalloc.so.2
ENV APP_DIR /usr/src/app

RUN <<EOT
#!/usr/bin/env bash
  mkdir $APP_DIR/log
  chown $APP_USER:$APP_USER $APP_DIR/log
  mkdir $APP_DIR/tmp
  chown $APP_USER:$APP_USER $APP_DIR/tmp
EOT

# Copy the application
USER $APP_USER
COPY --chown=$APP_USER:$APP_USER \
     Gemfile \
     Gemfile.lock \
     Rakefile \
     config.ru \
     entrypoint.sh \
     $APP_DIR/
COPY --chown=$APP_USER:$APP_USER ./public $APP_DIR/public
COPY --chown=$APP_USER:$APP_USER ./bin $APP_DIR/bin
COPY --chown=$APP_USER:$APP_USER ./config $APP_DIR/config
COPY --chown=$APP_USER:$APP_USER ./db $APP_DIR/db
COPY --chown=$APP_USER:$APP_USER ./lib $APP_DIR/lib
COPY --chown=$APP_USER:$APP_USER ./app $APP_DIR/app
COPY --chown=$APP_USER:$APP_USER ./.pryrc $APP_DIR/.pryrc

# Generate a SHA revision file
ARG SOURCE_COMMIT
RUN echo "${SOURCE_COMMIT:-unknown}" > $APP_DIR/revision

ENTRYPOINT ["./entrypoint.sh"]
