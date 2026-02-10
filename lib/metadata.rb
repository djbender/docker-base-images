require_relative 'tag_generator'
require_relative 'cache_ref'

# This class could be replaced with something like OpenStruct,
# but having a dedicated class makes it easy to add helper methods to the ERB templates
class Metadata
  def initialize(values)
    @values = values
    values.each do |key, value|
      instance_variable_set(:"@#{key}", value)
      define_singleton_method(key.to_s) { value }
    end
  end

  # NOTE: see ../manifest.yml for values passed into the initialize method
  # some of the methods defined here, use those values if they exist
  def get_binding # rubocop:disable Naming/AccessorMethodName
    binding
  end

  def full_image_path
    "ghcr.io/djbender/#{image_name}"
  end

  def context_path
    "#{original_image_name}/#{original_version}"
  end

  # Delegate to TagGenerator for consistent tag generation
  def docker_tags
    TagGenerator.primary_tags(image_name, @values)
  end

  def docker_dev_tags
    TagGenerator.dev_tags(image_name, @values)
  end

  # Cache configuration for primary target
  def cache_from
    reg = "#{registry}/#{image_name}"
    [CacheRef.from(reg, version), "type=registry,ref=#{reg}:#{version}"]
  end

  def cache_to
    [CacheRef.to("#{registry}/#{image_name}", version)]
  end

  # Cache configuration for dev target
  def cache_from_dev
    reg = "#{registry}/#{image_name}"
    [CacheRef.from(reg, "dev-#{version}"), "type=registry,ref=#{reg}:dev-#{version}"]
  end

  def cache_to_dev
    [CacheRef.to("#{registry}/#{image_name}", "dev-#{version}")]
  end

  # Format a Ruby array as an HCL list with proper indentation
  def hcl_list(items, indent: 2)
    pad = ' ' * indent
    inner = ' ' * (indent + 2)
    if items.size == 1
      "[#{items.first.inspect}]"
    else
      entries = items.map { |i| "#{inner}#{i.inspect}" }.join(",\n")
      "[\n#{entries}\n#{pad}]"
    end
  end

  def branch_suffix
    branch_name = ENV['GITHUB_REF_NAME'] || 'main'
    branch_name == 'main' ? '' : "-#{branch_name.gsub(/[^a-zA-Z0-9\-_]/, '-')}"
  end

  # return nil if you try to call a method that doesn't exist
  def method_missing(_method_name, *_args, &); end
  def respond_to_missing?(_method_name); end
end
