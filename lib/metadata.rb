# This class could be replaced with something like OpenStruct,
# but haveing a dedicated class makes it easy to add helper methods to the ERB templates
class Metadata
  def initialize(values)
    values.each do |key, value|
      instance_variable_set(:"@#{key}", value)
      define_singleton_method(key.to_s) { value }
    end
  end

  # NOTE: see ../manifest.yml for values passed into the initialize method
  # some of the methods defined here, use those vaules if they exist
  def get_binding # rubocop:disable Naming/AccessorMethodName
    binding
  end

  def full_image_path
    "ghcr.io/djbender/#{image_name}"
  end

  def docker_tags(custom_tags = [])
    custom_tags = custom_tags.push(additional_tags).flatten.compact.uniq
    default_docker_tags.push(custom_tags).flatten.compact.uniq.sort
  end

  # return nil if you try to call a method that doesn't exist
  def method_missing(_method_name, *_args, &); end
  def respond_to_missing?(_method_name); end

  private

  def github_sha
    ENV.fetch('GITHUB_SHA', nil)
  end

  # Examples
  # "#{full_image_path}:#{version}" == ghcr.io/djbender/ruby:3.3
  def default_docker_tags
    [].tap do |tags_array|
      tags_array.push(default_flavor_tag, default_version_tag)
      tags_array.push("#{full_image_path}:#{github_sha}") if github_sha
      tags_array.push("#{full_image_path}:latest") if latest
      tags_array.push("#{full_image_path}:rolling") if rolling
    end.flatten.compact.uniq
  end

  # Ensures flavor tags exist
  # Example:
  #   ruby:3.1-slim ruby:3.1-dev
  def default_flavor_tag
    if flavor && !flavor&.empty?
      local_flavor_tag = version.include?(flavor) ? version : "#{version}-#{flavor}"
      default_flavor_tag = "#{full_image_path}:#{local_flavor_tag}"
      [default_flavor_tag]
    else
      []
    end
  end

  # Ensures non flavor tags exist
  # and if flavor exists, apply it != dev image
  # Example:
  #   ruby:3.1 ruby:3.1-slim point at the same image
  #   ruby:3.1-dev will not have the non flavor tag
  def default_version_tag
    if flavor&.casecmp('dev')&.zero?
      []
    else
      ["#{full_image_path}:#{version}"]
    end
  end
end
