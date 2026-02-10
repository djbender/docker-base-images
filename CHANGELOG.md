# Changelog

## Unreleased

### Added
- GitHub Pages documentation site with Sinatra + Parklife static build
- `lib/manifest_loader.rb` - shared manifest loading independent of Rake
- `lib/site_manifest.rb` - manifest data layer for the documentation site
- `deploy-docs.yml` workflow for automatic GitHub Pages deployment

### Fixed
- Update core/README.md: add noble tags, remove stale slim tags
- Update ruby/README.md: add all current versions/tags (2.4-4.0), fix patch versions and distro suffixes

### Added
- RSpec and RuboCop run in CI workflow
- SimpleCov with branch coverage for RSpec tests
- Native ARM64 builds using `ubuntu-24.04-arm` runners - significantly faster than QEMU emulation (ruby builds drop from ~40min to ~10min)
- `lib/tag_generator.rb` - centralized tag generation for all image types
- Merge jobs to create multi-arch manifests after platform-specific builds
- `{major}-dev` tag for Ruby images (e.g., `ruby:3.3-dev`) - now matches Node pattern
- CI gate job for stable branch protection check
- Ruby 4.0 support (4.0.1)
- Node 25 support
- Orphan directory cleanup during generation - prompts before removing directories no longer in manifest (auto-confirms in non-TTY/CI environments)
- `.generated.yml` tracks generated directories for cleanup detection

### Removed
- Node 8, 10, 12, 14 (NodeSource GPG key no longer available for old repos)
- Node 21
- Node 23

### Changed
- Add Derek Bender copyright to LICENSE alongside original Bridge copyright
- Centralize cache config: `CacheRef` module builds cache ref strings, `HclFormatter` handles HCL list formatting for all array values in bake templates (#251)
- Add `rubocop-rspec`, exclude `bin/` from rubocop
- Centralize registry config: `ghcr.io/djbender` now defined once in `manifest.yml` globals (#250)
- Centralize `platforms` config in `manifest.yml` globals (previously hardcoded in templates)
- Node 25: 25.3.0 → 25.6.0
- dependabot.yml updated for node version changes
- .rubocop.yml migrated from `require` to `plugins` syntax
- Use `YAML.safe_load_file` for security in ImageGenerator

### Removed (code)
- Unused `copy_non_template_files` method from ImageGenerator
