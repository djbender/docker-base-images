# Changelog

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
