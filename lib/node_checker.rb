require 'json'
require_relative 'version_checker'

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

    pattern = /node_version: #{Regexp.escape(current)}(\s+)npm_version: #{Regexp.escape(current_npm)}/
    replacement = "node_version: #{up[:version]}\\1npm_version: #{up[:npm]}"

    Update.new(key: key, current: current, latest: up[:version],
               replacements: { pattern => replacement })
  end
end
