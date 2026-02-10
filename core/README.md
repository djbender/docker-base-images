# Core

Core images are built using ubuntu for ease of development and maintenance.

The core images come in two flavors. The bare number tags target production
deployments and are kept as slim as possible. The `-dev` images target
development and testing and include development libraries for easy building
of production assets.

Available tags:
- [`noble`, `latest`](ghcr.io/djbender/core:noble)
- [`noble-dev`, `dev`](ghcr.io/djbender/core:noble-dev)
- [`jammy`](ghcr.io/djbender/core:jammy)
- [`jammy-dev`](ghcr.io/djbender/core:jammy-dev)
- [`bionic`](ghcr.io/djbender/core:bionic)
- [`bionic-dev`](ghcr.io/djbender/core:bionic-dev)
