require_relative '../lib/manifest_loader'
require_relative '../lib/tag_generator'

# Read-only manifest data layer for the documentation site.
# Loads manifest.yml without requiring Rake.
module SiteManifest
  class << self
    def registry
      @registry ||= ManifestLoader.registry
    end

    def image_types
      @image_types ||= manifest.keys.map { |name| image_type(name) }
    end

    def image_type(name)
      name = name.to_s
      defaults = merged_defaults(name)
      versions = build_versions(name, defaults)
      ImageType.new(name, versions)
    end

    private

    def build_versions(name, defaults)
      manifest.fetch(name).fetch('versions').map do |version_key, version_values|
        attrs = defaults.merge(version_values || {})
        attrs['version'] = version_key.to_s
        attrs = interpolate_registry(attrs)
        ImageType::Version.new(version_key.to_s, attrs, name)
      end
    end

    def merged_defaults(name)
      global_defaults.merge(manifest.fetch(name).fetch('defaults', {}))
    end

    def manifest
      @manifest ||= ManifestLoader.load.except('globals')
    end

    def globals
      @globals ||= ManifestLoader.load.fetch('globals', {})
    end

    def global_defaults
      @global_defaults ||= globals.fetch('defaults', {})
    end

    def interpolate_registry(hash)
      hash.transform_values do |v|
        v.is_a?(String) ? format(v, registry: registry) : v
      end
    end
  end

  class ImageType
    attr_reader :name, :versions

    def initialize(name, versions)
      @name = name
      @versions = versions
    end

    def latest_version
      versions.find { |v| v.attrs['latest'] } || versions.last
    end

    # Plain class instead of Struct to avoid overriding Struct#values
    class Version
      attr_reader :key, :attrs, :image_type_name

      def initialize(key, attrs, image_type_name)
        @key = key
        @attrs = attrs
        @image_type_name = image_type_name
      end

      def primary_tags
        TagGenerator.primary_tags(image_type_name, attrs)
      end

      def dev_tags
        TagGenerator.dev_tags(image_type_name, attrs)
      end
    end
  end
end
