# docker-base-images
[![Build Images](https://github.com/djbender/docker-base-images/actions/workflows/build-images.yml/badge.svg)](https://github.com/djbender/docker-base-images/actions/workflows/build-images.yml)

Multi architecture docker base images

Available images:
- [Core - Ubuntu Bionic, Jammy, Noble](core/)
- [Ruby](ruby/)
- [Node](node/)

# How to build
- [Optional] Log in to ghcr.io for build cache

    $ echo $GHCR_PAT | docker login ghcr.io -u USERNAME --password-stdin
    > Login Succeeded

Note: without this step, you'll see messages like when building:

    #9 importing cache manifest from ghcr.io/djbender/core:jammy-cache
    #9 ERROR: failed to configure registry cache importer: failed to authorize: failed to fetch anonymous token: unexpected status: 401 Unauthorized

- `docker buildx bake -f core/jammy/docker-bake.hcl`
- or if you get an error `PWD=$(pwd) docker buildx bake -f core/jammy/docker-bake.hcl`

## Development
We use `ruby` , and `erb` templates to generate our Dockerfile's
- Install `ruby`, ([chruby](https://github.com/postmodern/chruby), or [asdf](https://github.com/asdf-vm/asdf))
- `bundle install`
- `bundle exec rake -T` to see rake tasks

You can install some useful git-hooks by install [overcommit](https://github.com/sds/overcommit#installation)
- `gem install overcommit`
- `cp .overcommit.sample.yml .overcommit.yml`
- `overcommit --install`
