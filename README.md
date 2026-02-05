# docker-base-images
[![Build Images](https://github.com/djbender/docker-base-images/actions/workflows/build-images.yml/badge.svg)](https://github.com/djbender/docker-base-images/actions/workflows/build-images.yml)

Multi architecture docker base images

Available images:
- [Core - Ubuntu Bionic, Jammy, Noble](core/)
- [Ruby](ruby/)
- [Node](node/)

# How to build

```bash
docker buildx bake -f ruby/4.0/docker-bake.hcl
```

To build only for your native architecture (faster, loads image locally):

```bash
docker buildx bake -f ruby/4.0/docker-bake.hcl \
  --set '*.platform=linux/arm64' \
  --set '*.cache-from=' \
  --set '*.cache-to=' \
  --load
```

## Build cache (optional)

Log in to ghcr.io for faster builds:

```bash
echo $GHCR_PAT | docker login ghcr.io -u USERNAME --password-stdin
```

Without this, you'll see errors like:
```
#9 importing cache manifest from ghcr.io/djbender/core:jammy-cache
#9 ERROR: failed to configure registry cache importer: failed to authorize: failed to fetch anonymous token: unexpected status: 401 Unauthorized
```

## Development
We use `ruby` , and `erb` templates to generate our Dockerfile's
- Install `ruby`, ([chruby](https://github.com/postmodern/chruby), or [asdf](https://github.com/asdf-vm/asdf))
- `bundle install`
- `bundle exec rake -T` to see rake tasks

You can install some useful git-hooks by install [overcommit](https://github.com/sds/overcommit#installation)
- `gem install overcommit`
- `cp .overcommit.sample.yml .overcommit.yml`
- `overcommit --install`
