require 'json'
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
      update.replacements.each { |old, new_val| content.gsub!(old, new_val) }
    end
  end

  private

  def compare(_key, _config, _upstream) = raise(NotImplementedError)
end

class RubyChecker < VersionChecker
  RUBY_INDEX_URL = 'https://cache.ruby-lang.org/pub/ruby/index.txt'.freeze

  def manifest_key = 'ruby'

  def fetch_upstream # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    index = URI.parse(RUBY_INDEX_URL).open.read
    latest = {}

    index.each_line do |line|
      next unless line.match?(/\Aruby-\d+\.\d+\.\d+\t.*\.tar\.xz\t/)

      version = line[/\Aruby-(\d+\.\d+\.\d+)/, 1]
      sha256 = line.split("\t")[3].strip
      major_minor = version.split('.')[0..1].join('.')

      if !latest[major_minor] || Gem::Version.new(version) > Gem::Version.new(latest[major_minor][:version])
        latest[major_minor] = { version: version, sha256: sha256 }
      end
    end

    latest
  end

  private

  def compare(key, config, upstream) # rubocop:disable Metrics/MethodLength
    current = config['ruby_version']
    current_sha = config['ruby_download_sha256']
    up = upstream[key]
    return unless up
    return if up[:version] == current

    Update.new(
      key: key,
      current: current,
      latest: up[:version],
      replacements: {
        "ruby_version: #{current}" => "ruby_version: #{up[:version]}",
        "ruby_download_sha256: #{current_sha}" => "ruby_download_sha256: #{up[:sha256]}"
      }
    )
  end
end

class NodeChecker < VersionChecker
  NODE_INDEX_URL = 'https://nodejs.org/dist/index.json'.freeze

  def manifest_key = 'node'

  def fetch_upstream # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    releases = JSON.parse(URI.parse(NODE_INDEX_URL).open.read)
    latest = {}

    releases.each do |release|
      version = release['version'].delete_prefix('v')
      npm = release['npm']
      major = version.split('.').first

      gem_ver = Gem::Version.new(version)
      if !latest[major] || gem_ver > Gem::Version.new(latest[major][:version])
        latest[major] = { version: version, npm: npm }
      end
    end

    latest
  end

  private

  def compare(key, config, upstream)
    current = config['node_version']
    current_npm = config['npm_version']
    up = upstream[key]
    return unless up
    return if up[:version] == current

    # Use multi-line anchor to scope npm replacement to the same version block,
    # avoiding gsub collisions when multiple versions share an npm_version value.
    old_block = "node_version: #{current}\n      npm_version: #{current_npm}"
    new_block = "node_version: #{up[:version]}\n      npm_version: #{up[:npm]}"

    Update.new(key: key, current: current, latest: up[:version],
               replacements: { old_block => new_block })
  end
end
