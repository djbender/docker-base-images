require_relative '../lib/version_checker'

RSpec.describe VersionChecker do
  describe '#check' do
    it 'raises NotImplementedError for base class' do
      checker = described_class.new
      expect { checker.check({}) }.to raise_error(NotImplementedError)
    end
  end

  describe '#apply!' do
    it 'performs gsub replacements on content' do
      checker = described_class.new
      content = +'node_version: 20.0.0'
      updates = [
        VersionChecker::Update.new(
          key: '20', current: '20.0.0', latest: '20.1.0',
          replacements: { 'node_version: 20.0.0' => 'node_version: 20.1.0' }
        )
      ]

      checker.apply!(content, updates)
      expect(content).to eq('node_version: 20.1.0')
    end
  end

  describe RubyChecker do
    subject(:checker) { described_class.new }

    let(:ruby_index) do
      <<~INDEX
        ruby-3.3.9\thttps://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.9.tar.gz\t123\toldsha
        ruby-3.3.9\thttps://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.9.tar.xz\t456\toldsha_xz
        ruby-3.3.10\thttps://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.10.tar.xz\t789\tnewsha_xz
        ruby-3.3.8\thttps://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.8.tar.xz\t000\tskipped
        ruby-3.4.2\thttps://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.2.tar.xz\t101\tsha34
      INDEX
    end

    let(:manifest) do
      {
        'ruby' => {
          'versions' => {
            '3.3' => { 'ruby_version' => '3.3.9', 'ruby_download_sha256' => 'oldsha_xz' },
            '3.4' => { 'ruby_version' => '3.4.2', 'ruby_download_sha256' => 'sha34' }
          }
        }
      }
    end

    before do
      io = instance_double(StringIO, read: ruby_index)
      allow(URI).to receive(:parse).and_return(instance_double(URI::HTTPS, open: io))
    end

    describe '#manifest_key' do
      it 'returns ruby' do
        expect(checker.manifest_key).to eq('ruby')
      end
    end

    describe '#check' do
      it 'returns updates for outdated versions' do
        updates = checker.check(manifest)

        expect(updates.size).to eq(1)
        expect(updates.first.key).to eq('3.3')
        expect(updates.first.current).to eq('3.3.9')
        expect(updates.first.latest).to eq('3.3.10')
      end

      it 'returns empty array when up to date' do
        manifest['ruby']['versions']['3.3']['ruby_version'] = '3.3.10'
        manifest['ruby']['versions']['3.3']['ruby_download_sha256'] = 'newsha_xz'

        expect(checker.check(manifest)).to be_empty
      end

      it 'skips versions not found upstream' do
        manifest['ruby']['versions']['2.0'] = { 'ruby_version' => '2.0.0', 'ruby_download_sha256' => 'abc' }
        updates = checker.check(manifest)

        expect(updates.map(&:key)).not_to include('2.0')
      end

      it 'includes sha256 replacements' do
        update = checker.check(manifest).first

        expect(update.replacements).to eq(
          'ruby_version: 3.3.9' => 'ruby_version: 3.3.10',
          'ruby_download_sha256: oldsha_xz' => 'ruby_download_sha256: newsha_xz'
        )
      end
    end

    describe '#apply!' do
      it 'updates manifest content string' do
        content = +"ruby_version: 3.3.9\nruby_download_sha256: oldsha_xz\nruby_version: 3.4.2"
        updates = checker.check(manifest)

        checker.apply!(content, updates)
        expect(content).to include('ruby_version: 3.3.10')
        expect(content).to include('ruby_download_sha256: newsha_xz')
        expect(content).to include('ruby_version: 3.4.2')
      end
    end
  end

  describe NodeChecker do
    subject(:checker) { described_class.new }

    let(:node_releases) do
      [
        { 'version' => 'v22.5.0', 'npm' => '10.9.0' },
        { 'version' => 'v22.4.0', 'npm' => '10.8.0' },
        { 'version' => 'v20.18.0', 'npm' => '10.8.2' },
        { 'version' => 'v20.17.0', 'npm' => '10.7.0' }
      ].to_json
    end

    let(:manifest) do
      {
        'node' => {
          'versions' => {
            '22' => { 'node_version' => '22.4.0', 'npm_version' => '10.8.0' },
            '20' => { 'node_version' => '20.18.0', 'npm_version' => '10.8.2' }
          }
        }
      }
    end

    before do
      io = instance_double(StringIO, read: node_releases)
      allow(URI).to receive(:parse).and_return(instance_double(URI::HTTPS, open: io))
    end

    describe '#manifest_key' do
      it 'returns node' do
        expect(checker.manifest_key).to eq('node')
      end
    end

    describe '#check' do
      it 'returns updates for outdated versions' do
        updates = checker.check(manifest)

        expect(updates.size).to eq(1)
        expect(updates.first.key).to eq('22')
        expect(updates.first.current).to eq('22.4.0')
        expect(updates.first.latest).to eq('22.5.0')
      end

      it 'returns empty array when up to date' do
        manifest['node']['versions']['22']['node_version'] = '22.5.0'
        manifest['node']['versions']['22']['npm_version'] = '10.9.0'

        expect(checker.check(manifest)).to be_empty
      end

      it 'skips versions not found upstream' do
        manifest['node']['versions']['99'] = { 'node_version' => '99.0.0', 'npm_version' => '1.0.0' }
        updates = checker.check(manifest)

        expect(updates.map(&:key)).not_to include('99')
      end

      it 'includes node_version and npm_version as a block replacement' do
        update = checker.check(manifest).first

        expect(update.replacements).to eq(
          "node_version: 22.4.0\n      npm_version: 10.8.0" =>
            "node_version: 22.5.0\n      npm_version: 10.9.0"
        )
      end

      it 'does not collide when multiple versions share npm_version' do
        manifest['node']['versions']['20']['npm_version'] = '10.8.0'
        manifest['node']['versions']['20']['node_version'] = '20.17.0'

        lines = [
          'node_version: 22.4.0', '      npm_version: 10.8.0',
          'node_version: 20.17.0', '      npm_version: 10.8.0'
        ]
        content = +lines.join("\n")
        updates = checker.check(manifest)
        checker.apply!(content, updates)

        expect(content).to include("node_version: 22.5.0\n      npm_version: 10.9.0")
        expect(content).to include("node_version: 20.18.0\n      npm_version: 10.8.2")
      end
    end

    describe '#apply!' do
      it 'updates manifest content string' do
        lines = [
          'node_version: 22.4.0', '      npm_version: 10.8.0',
          'node_version: 20.18.0', '      npm_version: 10.8.2'
        ]
        content = +lines.join("\n")
        updates = checker.check(manifest)

        checker.apply!(content, updates)
        expect(content).to include("node_version: 22.5.0\n      npm_version: 10.9.0")
        expect(content).to include("node_version: 20.18.0\n      npm_version: 10.8.2")
      end
    end
  end
end
