# Changelog

## Unreleased

### Added
- Node 25 support
- Orphan directory cleanup during generation - prompts before removing directories no longer in manifest (auto-confirms in non-TTY/CI environments)
- `.generated.yml` tracks generated directories for cleanup detection

### Removed
- Node 21
- Node 23

### Changed
- dependabot.yml updated for node version changes
- .rubocop.yml migrated from `require` to `plugins` syntax
- Use `YAML.safe_load_file` for security in ImageGenerator

### Removed (code)
- Unused `copy_non_template_files` method from ImageGenerator
