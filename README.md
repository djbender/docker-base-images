# docker-base-images
[![Build Images](https://github.com/djbender/docker-base-images/actions/workflows/build-images.yml/badge.svg)](https://github.com/djbender/docker-base-images/actions/workflows/build-images.yml)

Multi-architecture (amd64/arm64) Docker base images published to `ghcr.io/djbender`.

## Available images

| Image | Versions |
|-------|----------|
| [Core](core/) | `resolute`, `noble` (latest), `jammy`, `bionic` — includes `-dev` variants |
| [Ruby](ruby/) | `2.4`, `2.5`, `2.6`, `2.7`, `3.0`, `3.1`, `3.2`, `3.3`, `3.4`, `4.0` (latest) |
| [Node](node/) | `16`, `18`, `20`, `22`, `24` (latest), `25` |

## Building images

```bash
docker buildx bake -f ruby/4.0/docker-bake.hcl
```

To build for your native architecture only (faster, loads image locally):

```bash
docker buildx bake -f ruby/4.0/docker-bake.hcl \
  --set '*.platform=linux/arm64' \
  --set '*.cache-from=' \
  --set '*.cache-to=' \
  --load
```

### Build cache (optional)

Log in to ghcr.io for faster builds using the remote layer cache:

```bash
echo $GHCR_PAT | docker login ghcr.io -u USERNAME --password-stdin
```

Without this you'll see 401 errors when pulling cache manifests — builds still work, just slower.

## Development

Images are defined in [`manifest.yml`](manifest.yml). Dockerfiles and bake configs are auto-generated from ERB templates — never edit them directly.

```bash
bin/rake generate:all        # regenerate all Dockerfiles from templates
bin/rake generate:[core|ruby|node]  # regenerate specific image type
bin/rubocop                  # lint
bin/rspec                    # tests
```

### Setup

- Install Ruby ([chruby](https://github.com/postmodern/chruby) or [asdf](https://github.com/asdf-vm/asdf))
- `bin/bundle install`
- `bin/rake -T` to list all tasks

### Git hooks (optional)

```bash
gem install overcommit
cp .overcommit.sample.yml .overcommit.yml
overcommit --install
```
