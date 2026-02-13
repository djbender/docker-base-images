require_relative '../lib/ruby_checker'

RSpec.describe RubyChecker do
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
      manifest['ruby']['versions']['2.0'] = {
        'ruby_version' => '2.0.0', 'ruby_download_sha256' => 'abc'
      }
      updates = checker.check(manifest)

      expect(updates.map(&:key)).not_to include('2.0')
    end

    it 'uses regex replacement that captures whitespace' do
      update = checker.check(manifest).first
      pattern, replacement = update.replacements.first

      expect(pattern).to be_a(Regexp)
      expect(pattern).to match("ruby_version: 3.3.9\n      ruby_download_sha256: oldsha_xz")
      expect(replacement).to include('ruby_version: 3.3.10')
      expect(replacement).to include('ruby_download_sha256: newsha_xz')
    end
  end

  describe '#apply!' do
    it 'updates manifest content preserving indentation' do
      content = +"      ruby_version: 3.3.9\n      ruby_download_sha256: oldsha_xz\n      ruby_version: 3.4.2"
      updates = checker.check(manifest)

      checker.apply!(content, updates)
      expect(content).to include("ruby_version: 3.3.10\n      ruby_download_sha256: newsha_xz")
      expect(content).to include('ruby_version: 3.4.2')
    end

    it 'preserves varying indentation' do
      content = +"    ruby_version: 3.3.9\n    ruby_download_sha256: oldsha_xz"
      updates = checker.check(manifest)

      checker.apply!(content, updates)
      expect(content).to eq("    ruby_version: 3.3.10\n    ruby_download_sha256: newsha_xz")
    end
  end
end
