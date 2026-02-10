require 'yaml'

# Shared manifest loading, independent of Rake.
# Used by Util (Rake context) and SiteManifest (web context).
module ManifestLoader
  MANIFEST_PATH = File.expand_path('../manifest.yml', __dir__).freeze

  def self.load
    YAML.load_file(MANIFEST_PATH, aliases: true)
  end

  def self.registry
    manifest = load
    manifest.dig('globals', 'defaults', 'registry')
  end
end
