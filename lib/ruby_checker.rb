require_relative 'version_checker'

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

  def compare(key, config, upstream)
    current = config['ruby_version']
    current_sha = config['ruby_download_sha256']
    up = upstream[key]
    return unless up
    return if up[:version] == current

    pattern = /ruby_version: #{Regexp.escape(current)}(\s+)ruby_download_sha256: #{Regexp.escape(current_sha)}/
    replacement = "ruby_version: #{up[:version]}\\1ruby_download_sha256: #{up[:sha256]}"

    Update.new(key: key, current: current, latest: up[:version],
               replacements: { pattern => replacement })
  end
end
