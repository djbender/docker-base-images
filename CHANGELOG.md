# Changelog

## Unreleased

### Added
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
- Node 25: 25.3.0 → 25.6.0
- dependabot.yml updated for node version changes
- .rubocop.yml migrated from `require` to `plugins` syntax
- Use `YAML.safe_load_file` for security in ImageGenerator

### Removed (code)
- Unused `copy_non_template_files` method from ImageGenerator
