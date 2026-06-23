require_relative '../lib/version_checker'

RSpec.describe VersionChecker do
  let(:stub_checker_class) do
    Class.new(VersionChecker) do
      def manifest_key = 'pkg'

      def fetch_upstream
        {
          '1.0' => { version: '1.1', extra: 'data' },
          '2.0' => { version: '2.0', extra: 'same' }
        }
      end

      private

      def compare(key, config, upstream)
        up = upstream[key]
        return unless up
        return if up[:version] == config['pkg_version']

        VersionChecker::Update.new(
          key: key, current: config['pkg_version'], latest: up[:version],
          replacements: { /pkg_version: #{config['pkg_version']}/ => "pkg_version: #{up[:version]}" }
        )
      end
    end
  end

  let(:checker) { stub_checker_class.new }

  let(:manifest) do
    {
      'pkg' => {
        'versions' => {
          '1.0' => { 'pkg_version' => '1.0' },
          '2.0' => { 'pkg_version' => '2.0' }
        }
      }
    }
  end

  describe '#manifest_key' do
    it 'raises NotImplementedError on base class' do
      expect { described_class.new.manifest_key }.to raise_error(NotImplementedError)
    end
  end

  describe '#fetch_upstream' do
    it 'raises NotImplementedError on base class' do
      expect { described_class.new.fetch_upstream }.to raise_error(NotImplementedError)
    end
  end

  describe '#check' do
    it 'raises NotImplementedError for base class' do
      expect { described_class.new.check({}) }.to raise_error(NotImplementedError)
    end

    it 'returns updates for outdated versions' do
      updates = checker.check(manifest)

      expect(updates.size).to eq(1)
      expect(updates.first.key).to eq('1.0')
      expect(updates.first.current).to eq('1.0')
      expect(updates.first.latest).to eq('1.1')
    end

    it 'returns empty array when all versions are up to date' do
      manifest['pkg']['versions']['1.0']['pkg_version'] = '1.1'

      expect(checker.check(manifest)).to be_empty
    end

    it 'skips versions not found upstream' do
      manifest['pkg']['versions']['99.0'] = { 'pkg_version' => '99.0' }

      updates = checker.check(manifest)
      expect(updates.map(&:key)).not_to include('99.0')
    end

    it 'returns an array' do
      expect(checker.check(manifest)).to be_an(Array)
    end

    it 'only processes versions under manifest_key namespace' do
      manifest['other_pkg'] = manifest['pkg'].dup
      manifest['pkg']['versions'] = {}

      expect(checker.check(manifest)).to be_empty
    end

    it 'returns empty array when manifest_key section is absent' do
      expect(checker.check({})).to be_empty
    end

    it 'collects multiple updates when several versions are outdated' do
      manifest['pkg']['versions']['2.0']['pkg_version'] = '1.9'

      updates = checker.check(manifest)
      expect(updates.size).to eq(2)
    end

    it 'passes upstream from fetch_upstream into compare' do
      allow(checker).to receive(:fetch_upstream).and_return({})

      expect(checker.check(manifest)).to be_empty
    end
  end

  describe '#compare' do
    it 'raises NotImplementedError on base class' do
      expect { described_class.new.send(:compare, nil, nil, nil) }.to raise_error(NotImplementedError)
    end
  end

  describe '#apply!' do
    it 'performs gsub replacements on content' do
      checker = described_class.new
      content = +'node_version: 20.0.0'
      updates = [
        VersionChecker::Update.new(
          key: '20', current: '20.0.0', latest: '20.1.0',
          replacements: { /node_version: 20\.0\.0/ => 'node_version: 20.1.0' }
        )
      ]

      checker.apply!(content, updates)
      expect(content).to eq('node_version: 20.1.0')
    end

    it 'raises with inspect of unmatched pattern in message' do
      checker = described_class.new
      allow(checker).to receive(:manifest_key).and_return('pkg')
      content = +'unrelated content'
      pattern = /pkg_version: 1\.0/
      updates = [
        VersionChecker::Update.new(
          key: '1.0', current: '1.0', latest: '1.1',
          replacements: { pattern => 'pkg_version: 1.1' }
        )
      ]

      expect { checker.apply!(content, updates) }
        .to raise_error(RuntimeError, /No match for pkg 1\.0: #{Regexp.escape(pattern.inspect)}/)
    end
  end
end
