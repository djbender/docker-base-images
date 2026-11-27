require 'rake'
require 'json'
require 'stringio'

Rake.application.rake_require('ci', [File.expand_path('../rakelib', __dir__)])

RSpec.describe 'rake ci:set-matrix' do # rubocop:disable RSpec/DescribeClass
  let(:env) do
    { 'GITHUB_REF' => 'refs/heads/main', 'GITHUB_EVENT_NAME' => nil, 'CHANGE_BASE' => nil, 'GITHUB_SHA' => nil }
  end
  let(:changed) { [] }

  around do |example|
    saved = ENV.to_h
    env.each { |key, value| ENV[key] = value }
    example.run
  ensure
    ENV.replace(saved)
  end

  before do
    allow(BuildScope::GitDiff).to receive(:new).and_return(->(_base) { changed })
  end

  def run(name)
    out = StringIO.new
    original_out = $stdout
    original_err = $stderr
    $stdout = out
    $stderr = StringIO.new
    Rake::Task["ci:set-matrix:#{name}"].execute
    JSON.parse(out.string).fetch('include')
  ensure
    $stdout = original_out
    $stderr = original_err
  end

  def images(name)
    run(name).map { |entry| "#{entry['primary_target']}/#{entry['version']}" }.uniq
  end

  context 'without a CI event' do
    it 'lists every core image' do
      expect(images('core')).to match_array(Util.image_dirs.grep(%r{^core/}))
    end

    it 'lists every other image' do
      expect(images('common')).to match_array(Util.image_dirs.grep_v(%r{^core/}))
    end
  end

  def noble_arm64
    run('core').find { |entry| entry['version'] == 'noble' && entry['arch'] == 'arm64' }
  end

  context 'with the main branch' do
    it 'caches to and from the arch tag' do
      expect(noble_arm64['primary_cache_from']).not_to include("\n")
      expect(noble_arm64['primary_cache_to']).to include('cache-noble-arm64,')
      expect(noble_arm64['runner']).to eq('ubuntu-24.04-arm')
    end
  end

  context 'with a feature branch' do
    let(:env) { super().merge('GITHUB_REF' => 'refs/heads/feat/x') }

    it 'writes a branch cache and falls back to the main cache' do
      expect(noble_arm64['primary_cache_to']).to include('cache-noble-arm64-feat-x,')
      expect(noble_arm64['primary_cache_from']).to match(/arm64-feat-x\n.*cache-noble-arm64\z/)
      expect(noble_arm64['dev_cache_from']).to match(/dev-noble-arm64-feat-x\n.*dev-noble-arm64\z/)
    end
  end

  context 'without GITHUB_REF' do
    let(:env) { super().merge('GITHUB_REF' => nil) }

    it 'reads the branch from the local checkout' do
      allow(Git).to receive(:open).and_return(double(current_branch: 'local'))

      expect(noble_arm64['primary_cache_to']).to include('cache-noble-arm64-local,')
    end
  end

  context 'with a partial build on main' do
    let(:base) { 'a' * 40 }
    let(:sha) { 'b' * 40 }
    let(:env) { super().merge('GITHUB_EVENT_NAME' => 'push', 'CHANGE_BASE' => base, 'GITHUB_SHA' => sha) }
    let(:changed) { ['node/22/Dockerfile'] }
    let(:registry) { Util::REGISTRY }

    def entry(version)
      run('common-merge').find { |e| e['primary_target'] == 'node' && e['version'] == version }
    end

    it 'lists every version for merging' do
      expect(images('common-merge')).to match_array(Util.image_dirs.grep_v(%r{^core/}))
      expect(images('core-merge')).to match_array(Util.image_dirs.grep(%r{^core/}))
    end

    it 'gives a built image all its tags and no re-tag sources' do
      expect(entry('22')['primary_tags'].split).to include("#{registry}/node:22", "#{registry}/node:22-#{sha}")
      expect(entry('22')).not_to include('primary_sources', 'dev_sources')
    end

    it 'gives an unchanged image only its SHA tags' do
      expect(entry('24')['primary_tags'].split)
        .to contain_exactly("#{registry}/node:#{sha}", "#{registry}/node:24-#{sha}")
      expect(entry('24')['dev_tags']).to eq("#{registry}/node:24-dev-#{sha}")
    end

    it 'lists the re-tag sources of an unchanged image in order of preference' do
      expect(entry('24')['primary_sources']).to eq("#{registry}/node:24-#{base} #{registry}/node:24")
      expect(entry('24')['dev_sources']).to eq("#{registry}/node:24-dev-#{base} #{registry}/node:24-dev")
    end

    context 'without a commit SHA' do
      let(:sha) { nil }

      it 'lists only built images' do
        expect(images('common-merge')).to eq(['node/22'])
      end
    end
  end

  context 'with a pull request' do
    let(:env) do
      super().merge('GITHUB_REF' => 'refs/pull/1/merge', 'GITHUB_EVENT_NAME' => 'pull_request',
                    'CHANGE_BASE' => 'a' * 40, 'GITHUB_SHA' => 'b' * 40)
    end
    let(:changed) { ['node/22/Dockerfile'] }

    it 'builds only the changed image' do
      expect(images('common')).to eq(['node/22'])
      expect(images('common-merge')).to eq(['node/22'])
    end

    it 'leaves the core matrices empty' do
      expect(run('core')).to eq([])
      expect(run('core-merge')).to eq([])
    end
  end
end
