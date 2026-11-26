require 'json'
require 'stringio'
require 'rake'
require 'yaml'

Rake.application.rake_require('ci', [File.expand_path('../rakelib', __dir__)])

# Invariants over the real manifest
RSpec.describe 'published tags' do # rubocop:disable RSpec/DescribeClass
  let(:sha) { '0123456789abcdef0123456789abcdef01234567' }
  let(:base) { 'f' * 40 }
  let(:versions) do
    Util.image_dirs.map { |dir| dir.split('/') }
  end

  def merge_entries(changed)
    saved = ENV.to_h
    ENV.update('GITHUB_REF' => 'refs/heads/main', 'GITHUB_EVENT_NAME' => 'push',
               'CHANGE_BASE' => base, 'GITHUB_SHA' => sha)
    allow(BuildScope::GitDiff).to receive(:new).and_return(->(_base) { changed })
    %w[core-merge common-merge].flat_map { |name| run_task(name) }
  ensure
    ENV.replace(saved)
  end

  def run_task(name)
    original_out = $stdout
    original_err = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    Rake::Task["ci:set-matrix:#{name}"].execute
    JSON.parse($stdout.string).fetch('include')
  ensure
    $stdout = original_out
    $stderr = original_err
  end

  def tags_of(entries)
    entries.flat_map { |entry| entry['primary_tags'].split + entry['dev_tags'].split }
  end

  it 'marks exactly one version of each image as latest' do
    counts = Util::MANIFEST.transform_values do |details|
      details.fetch('versions').values.count { |values| values&.fetch('latest', false) }
    end

    expect(counts).to eq(Util::MANIFEST.keys.to_h { |name| [name, 1] })
  end

  {
    'everything is built' => ['Rakefile'],
    'one image is built' => ['node/22/Dockerfile'],
    'nothing is built' => ['README.md']
  }.each do |scenario, changed|
    context "when #{scenario}" do
      let(:entries) { merge_entries(changed) }

      it 'writes no tag twice' do
        expect(tags_of(entries).tally.select { |_, count| count > 1 }).to eq({})
      end

      it 'gives every version a regular and a dev SHA tag' do
        expected = versions.flat_map do |image, version|
          ["#{Util::REGISTRY}/#{image}:#{version}-#{sha}", "#{Util::REGISTRY}/#{image}:#{version}-dev-#{sha}"]
        end
        expected += Util::MANIFEST.keys.map { |image| "#{Util::REGISTRY}/#{image}:#{sha}" }

        expect(tags_of(entries).grep(/#{sha}/)).to match_array(expected)
      end
    end
  end

  it 'only falls back to version tags that are published' do
    unpublished = versions.flat_map do |image, version|
      values = Util.version_values(image, version)
      [
        TagGenerator.primary_source_tags(image, values, base).last,
        TagGenerator.dev_source_tags(image, values, base).last
      ] - (TagGenerator.primary_tags(image, values) + TagGenerator.dev_tags(image, values))
    end

    expect(unpublished).to eq([])
  end

  it 'has no SHA tag that the cleanup workflow deletes' do
    workflow = YAML.load_file(File.expand_path('../.github/workflows/cleanup-packages.yml', __dir__))
    patterns = workflow.dig('jobs', 'cleanup', 'steps', 0, 'with', 'delete-tags').split(',')
    names = tags_of(merge_entries(['README.md'])).map { |tag| tag.split(':').last }

    expect(patterns).not_to be_empty
    expect(names.select { |name| patterns.any? { |pattern| File.fnmatch(pattern, name) } }).to eq([])
  end
end
