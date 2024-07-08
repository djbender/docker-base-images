# syntax=docker/dockerfile:1.4

####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:ruby`

########## Ruby image ##########################
FROM ghcr.io/djbender/core as ruby
LABEL org.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images

USER root

ARG APT_MIRROR

RUN <<EOT
#!/usr/bin/env bash
  set -eux
  mkdir -p /usr/src/app
  chown docker:docker /usr/src/app
  if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
    aptFile=/etc/apt/sources.list.d/ubuntu.sources
  else
    aptFile=/etc/apt/sources.list
  fi
  sed "s@ports.ubuntu.com@${APT_MIRROR:-ports.ubuntu.com}@" -i $aptFile
  apt-get update
  apt-get install --yes --no-install-recommends \
    bzip2 \
    curl \
    libffi-dev \
    libgmp-dev \
    libyaml-dev \
    procps \
    zlib1g-dev

  arch=$(dpkg --print-architecture)
  if [ "$arch" == "arm64" ]; then
    # Ruby versions older than or equal to 3.0 require an older version of openssl :| which is really annoying
    echo "deb http://${APT_MIRROR:-ports.ubuntu.com}/ubuntu-ports/ focal main restricted" >> /etc/apt/sources.list
    echo "deb http://${APT_MIRROR:-ports.ubuntu.com}/ubuntu-ports/ focal-updates main restricted" >> /etc/apt/sources.list
    echo "deb http://${APT_MIRROR:-ports.ubuntu.com}/ubuntu-ports/ focal-security main restricted" >> /etc/apt/sources.list
  else
    echo "deb http://${APT_MIRROR:-archive.ubuntu.com}/ubuntu/ focal main restricted" >> /etc/apt/sources.list
    echo "deb http://${APT_MIRROR:-archive.ubuntu.com}/ubuntu/ focal-updates main restricted" >> /etc/apt/sources.list
    echo "deb http://${APT_MIRROR:-security.ubuntu.com}/ubuntu/ focal-security main restricted" >> /etc/apt/sources.list
  fi

  apt-get update
  apt-get install --yes --allow-downgrades \
    libssl-dev=1.1.1* \
    openssl=1.1.1*
  apt-mark hold \
    libssl-dev \
    libssl1.1 \
    openssl
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
EOT

# skip installing gem documentation
COPY <<-"EOT" /usr/local/etc/gemrc
install: --no-document
update: --no-document
EOT

ENV BUNDLER_VERSION 2.5.14
ENV LANG en_US.utf-8
ENV RUBYGEMS_VERSION 3.5.14
ENV RUBY_DOWNLOAD_SHA256 1748338373c4fad80129921080d904aca326e41bd9589b498aa5ee09fd575bab
ENV RUBY_MAJOR 3.0
ENV RUBY_VERSION 3.0.7

# NOTE: some of ruby's build scripts are written in ruby so we need to install ruby
# in order to compile ruby. We use apt-mark to uninstall packages we don't need.
#
# Adapted from https://github.com/docker-library/ruby/blob/master
RUN <<EOT
#!/usr/bin/env bash
  set -eux
  savedAptMark="$(apt-mark showmanual)"
  apt-get update
  apt-get install --yes --no-install-recommends \
    autoconf \
    bison \
    dpkg-dev \
    g++ \
    gcc \
    libbz2-dev \
    libgdbm-compat-dev \
    libgdbm-dev \
    libglib2.0-dev \
    libncurses-dev \
    libreadline-dev \
    libxml2-dev \
    libxslt-dev \
    make \
    ruby \
    wget \
    xz-utils
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
  curl --remote-name --location https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz
  echo "$RUBY_DOWNLOAD_SHA256 ruby-$RUBY_VERSION.tar.xz" | sha256sum --check --strict
  mkdir -p /usr/src/ruby
  tar -xJf ruby-$RUBY_VERSION.tar.xz -C /usr/src/ruby --strip-components=1
  rm ruby-$RUBY_VERSION.tar.xz
  cd /usr/src/ruby
  # hack in "ENABLE_PATH_CHECK" disabling to suppress: warning: Insecure world writable dir
  sed -i 's/define ENABLE_PATH_CHECK 1/define ENABLE_PATH_CHECK 0/g' file.c
  autoconf
  # Should return something like `arm64`
  arch=$(dpkg --print-architecture)
  # Should return something like `linux-gnu`
  operating_system=$(uname -o | awk '{split($0,a,"/"); print tolower(a[2])"-"tolower(a[1])}')
  gnuArch="$arch-$operating_system"

  ./configure --build="$gnuArch" --disable-install-doc --enable-shared
  make -j "$(nproc)"
  make install
  apt-mark auto '.*' > /dev/null
  apt-mark manual $savedAptMark > /dev/null
  find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
          | awk '/=>/ { print $(NF-1) }' \
          | sort -u \
          | grep -vE '^/usr/local/lib/' \
          | xargs -r dpkg-query --search \
          | grep -v 'diversion' \
          | cut -d: -f1 \
          | sort -u \
          | xargs -r apt-mark manual
  apt-get purge --yes --auto-remove -o APT::AutoRemove::RecommendsImportant=false
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
  cd /
  rm -r /usr/src/ruby
  # Ensure we have removed the system ruby
  if dpkg -l | grep -i ruby; then exit 1; fi;
  # Update rubygems and bundler
  gem update  --no-document --system $RUBYGEMS_VERSION
  gem install --no-document bundler -v $BUNDLER_VERSION
  # Check that ruby commands work
  [ "$(command -v ruby)" = '/usr/local/bin/ruby' ]
  ruby --version
  gem --version
  bundle --version
EOT

# Set ruby defaults to docker user
USER docker

RUN <<EOT
#!/usr/bin/env bash
  set -eux
  echo 'gem: --no-document' >> /home/docker/.gemrc
  mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0/build_info \
           /home/docker/.gem/ruby/$RUBY_MAJOR.0/cache \
           /home/docker/.gem/ruby/$RUBY_MAJOR.0/doc \
           /home/docker/.gem/ruby/$RUBY_MAJOR.0/extensions \
           /home/docker/.gem/ruby/$RUBY_MAJOR.0/gems \
           /home/docker/.gem/ruby/$RUBY_MAJOR.0/specifications \
           /home/docker/.bundle

EOT

ENV GEM_HOME /home/docker/.gem/ruby/$RUBY_MAJOR.0
ENV BUNDLE_APP_CONFIG /home/docker/.bundle
ENV PATH $GEM_HOME/bin:$PATH
WORKDIR /usr/src/app

CMD [ "irb" ]

########## ruby-dev image ##########################
FROM ghcr.io/djbender/core as ruby-dev

ARG APT_MIRROR
USER root
RUN <<EOT
#!/usr/bin/env bash
  set -eux
  if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
    aptFile=/etc/apt/sources.list.d/ubuntu.sources
  else
    aptFile=/etc/apt/sources.list
  fi
  sed "s@ports.ubuntu.com@${APT_MIRROR:-ports.ubuntu.com}@" -i $aptFile
  apt-get update
  apt-get install --yes --no-install-recommends \
    autoconf \
    bison \
    dpkg-dev \
    g++ \
    gcc \
    imagemagick \
    libbz2-dev \
    libcurl4-openssl-dev \
    libevent-dev \
    libgdbm-compat-dev \
    libgdbm-dev \
    libjpeg-dev \
    libmagickcore-dev \
    libmagickwand-dev \
    libmysqlclient-dev \
    libncurses-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    make \
    wget \
    xz-utils
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
EOT

USER docker
