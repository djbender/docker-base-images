require 'open-uri'

class VersionChecker
  Update = Struct.new(:key, :current, :latest, :replacements, keyword_init: true)

  def manifest_key = raise(NotImplementedError)
  def fetch_upstream = raise(NotImplementedError)

  def check(manifest)
    versions = manifest.dig(manifest_key, 'versions')
    upstream = fetch_upstream

    versions.each_with_object([]) do |(key, config), updates|
      result = compare(key, config, upstream)
      updates << result if result
    end
  end

  def apply!(content, updates)
    updates.each do |update|
      update.replacements.each do |old, new_val|
        raise "No match for #{manifest_key} #{update.key}: #{old.inspect}" unless content.gsub!(old, new_val)
      end
    end
  end

  private

  def compare(_key, _config, _upstream) = raise(NotImplementedError)
end
