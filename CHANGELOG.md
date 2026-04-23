# Changelog

## 2026-04-23
- Pin nodesource origin via apt preferences so node 18/20 aren't shadowed by resolute's native nodejs 22.22.1
- Pin ruby 3.1 to noble (fails to compile under resolute's gcc 15/16 due to K&R-style declarations in upstream `enc/jis/props.kwd`)
- Promote resolute (Ubuntu 26.04) to default `core:latest`; ruby 3.1+ and node 18+ rebased from noble → resolute via the globals default
- Pin ruby 2.7 and 3.0 explicitly to noble (focal-apt openssl 1.1.1 workaround incompatible with resolute)

## 2026-04-20
- Add GitHub link to site main nav
- Sort image version tables descending (independent of manifest.yml order) so the latest version appears first
- Bump Node 25 to 25.9.0 (npm 11.12.1) to match nodesource upstream

## 2026-03-29
- Parallelize cleanup-packages via matrix (one job per package) to avoid 6h+ sequential runs
- Exclude `cache-*` tags from cleanup to preserve build cache

## 2026-03-28
- Pin `snok/container-retention-policy` to v3.0.1 (v3 tag doesn't exist, failing weekly since 2026-03-01)
- Rewrite README with image version table and clearer build/dev instructions
- Bump rubocop 1.85.1 → 1.86.0
- Fix cleanup-packages workflow: use humantime `cut-off` format and replace removed `tag-regex` with `image-tags` globs
- Fix cleanup-packages `account` from `djbender` to `user` (personal account literal required by v3), enable dry-run, remove debug curl
- Replace `snok/container-retention-policy` with `dataaxiom/ghcr-cleanup-action` for multi-arch-aware cleanup including untagged orphans

## 2026-03-25
- Bump Node 20 to 20.20.2, Node 22 to 22.22.2, Node 24 to 24.14.1, Node 25 to 25.8.2

## 2026-03-10
- Fix dev cache fallback ref: `dev-<version>` → `<version>-dev` to match actual image tags
- Local builds now pull CI's per-arch `mode=max` cache via `ARCH` HCL variable
- Remove `cache-to` from bake files (CI overrides via `--set`, local builds don't push)
- Dynamic arch detection in `build.rake` (overridable via `ARCH=amd64`)
- Echo full docker command before each build task runs

## 2026-03-05
- Remove stale dependabot entries for retired node versions (8, 10, 12, 14)

## 2026-02-13
- Fix docs site links missing GitHub Pages base path prefix (`/docker-base-images`)

## 2026-02-12
- `bin/check-versions` — unified version checker for Ruby + Node using Strategy pattern
- Split `VersionChecker`, `RubyChecker`, `NodeChecker` into separate files under `lib/`
- Block-scoped regex replacements to prevent gsub collisions across version entries
- `apply!` raises on unmatched replacements instead of silently skipping
- `track_files` in SimpleCov config to catch untested lib files

## 2026-02-10
- GitHub Pages documentation site with Sinatra + Parklife static build
- `lib/manifest_loader.rb` - shared manifest loading independent of Rake
- `lib/site_manifest.rb` - manifest data layer for the documentation site
- `deploy-docs.yml` workflow for automatic GitHub Pages deployment
- `SiteManifest`: use `.except('globals')` instead of destructive `.delete`
- `SiteManifest::Version`: accept image type name directly, remove `guess_image_name`
- Remove unused pass-through helpers from site app
- `deploy-docs.yml`: fix paths filter (remove redundant entry, add Gemfile/Gemfile.lock/.ruby-version)
- `bin/static-build`: use `cp -R site/public/.` to avoid glob expansion edge case
- Add SRI hash to Pico CSS CDN link
- Update core/README.md: add noble tags, remove stale slim tags
- Update ruby/README.md: add all current versions/tags (2.4-4.0), fix patch versions and distro suffixes
- Add Derek Bender copyright to LICENSE alongside original Bridge copyright
- Centralize cache config: `CacheRef` module builds cache ref strings, `HclFormatter` handles HCL list formatting for all array values in bake templates (#251)
- Add `rubocop-rspec`, exclude `bin/` from rubocop

## 2026-02-04
- SimpleCov with branch coverage for RSpec tests
- Centralize registry config: `ghcr.io/djbender` now defined once in `manifest.yml` globals (#250)
- Centralize `platforms` config in `manifest.yml` globals (previously hardcoded in templates)
- Native ARM64 builds using `ubuntu-24.04-arm` runners - significantly faster than QEMU emulation (ruby builds drop from ~40min to ~10min)
- Drop Node 8, 10, 12, 14 (NodeSource GPG key no longer available for old repos)
- Node 25: 25.3.0 → 25.6.0
- Orphan directory cleanup during generation - prompts before removing directories no longer in manifest (auto-confirms in non-TTY/CI environments)
- `.generated.yml` tracks generated directories for cleanup detection
- Add native architecture build instructions to README

## 2026-02-03
- CI gate job for stable branch protection check
- Ruby 4.0 support (4.0.1)
- `{major}-dev` tag for Ruby images (e.g., `ruby:3.3-dev`) - now matches Node pattern
- Merge jobs to create multi-arch manifests after platform-specific builds
- RSpec and RuboCop run in CI workflow
- dependabot.yml updated for node version changes
- .rubocop.yml migrated from `require` to `plugins` syntax
- Use `YAML.safe_load_file` for security in ImageGenerator
- Remove unused `copy_non_template_files` method from ImageGenerator
- Drop Node 21, 23
- Improve "How to build" section formatting in README
- Remove deprecated `docker buildx install` step
