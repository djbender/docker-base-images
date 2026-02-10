require_relative 'manifest_loader'

# Centralized tag generation for Docker images
# Used by both ERB templates and CI matrix generation
module TagGenerator
  REGISTRY = ManifestLoader.registry.freeze

  class << self
    # Generate primary (non-dev) tags for an image
    # @param image_name [String] e.g., 'core', 'ruby', 'node'
    # @param values [Hash] manifest values for this version
    # @return [Array<String>] full image tags
    def primary_tags(image_name, values)
      values = symbolize_keys(values)
      base = "#{REGISTRY}/#{image_name}"

      tags = default_primary_tags(base, values)
      tags += image_specific_tags(image_name, base, values)
      tags.flatten.compact.uniq.sort
    end

    # Generate dev tags for an image
    # @param image_name [String] e.g., 'core', 'ruby', 'node'
    # @param values [Hash] manifest values for this version
    # @return [Array<String>] full image tags
    def dev_tags(image_name, values)
      values = symbolize_keys(values)
      base = "#{REGISTRY}/#{image_name}"

      tags = default_dev_tags(base, values)
      tags += image_specific_dev_tags(image_name, base, values)
      tags.flatten.compact.uniq.sort
    end

    private

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end

    # Default tags applied to all images
    def default_primary_tags(base, values)
      tags = []
      version = values[:version]

      # Version tag (e.g., ruby:3.3)
      tags << "#{base}:#{version}" unless values[:flavor]&.casecmp('dev')&.zero?

      # Flavor tag if present (e.g., ruby:3.3-slim)
      if values[:flavor] && !values[:flavor].empty?
        flavor_tag = version.include?(values[:flavor]) ? version : "#{version}-#{values[:flavor]}"
        tags << "#{base}:#{flavor_tag}"
      end

      # SHA tag for traceability
      tags << "#{base}:#{github_sha}" if github_sha

      # Latest/rolling tags
      tags << "#{base}:latest" if values[:latest]
      tags << "#{base}:rolling" if values[:rolling]

      # Additional tags from manifest
      tags += Array(values[:additional_tags])

      tags
    end

    def default_dev_tags(base, values)
      tags = []

      tags << "#{base}:#{github_sha}" if github_sha
      tags << "#{base}:dev" if values[:latest]

      # Additional dev tags from manifest
      tags += Array(values[:additional_dev_tags])

      tags
    end

    # Image-specific primary tags
    def image_specific_tags(image_name, base, values)
      case image_name
      when 'core'
        [] # Core uses only default tags
      when 'ruby', 'node'
        lang_primary_tags(image_name, base, values)
      else
        []
      end
    end

    # Image-specific dev tags
    def image_specific_dev_tags(image_name, base, values)
      case image_name
      when 'core'
        core_dev_tags(base, values)
      when 'ruby', 'node'
        lang_dev_tags(image_name, base, values)
      else
        []
      end
    end

    def core_dev_tags(base, values)
      ["#{base}:#{values[:distribution_code_name]}-dev"]
    end

    # Unified primary tags for language images (ruby, node)
    def lang_primary_tags(image_name, base, values)
      full_version = values[:"#{image_name}_version"]
      major = values[:"#{image_name}_major"]
      dist = values[:distribution_code_name]

      [
        "#{base}:#{full_version}",
        "#{base}:#{full_version}-#{dist}",
        "#{base}:#{major}",
        "#{base}:#{major}-#{dist}"
      ]
    end

    # Unified dev tags for language images (ruby, node)
    def lang_dev_tags(image_name, base, values)
      full_version = values[:"#{image_name}_version"]
      major = values[:"#{image_name}_major"]
      dist = values[:distribution_code_name]

      [
        "#{base}:#{full_version}-dev-#{dist}",
        "#{base}:#{full_version}-dev",
        "#{base}:#{major}-dev-#{dist}",
        "#{base}:#{major}-dev"
      ]
    end

    def github_sha
      ENV.fetch('GITHUB_SHA', nil)
    end
  end
end
