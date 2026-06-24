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

  describe '#fetch_upstream' do
    it 'fetches the index from RUBY_INDEX_URL' do
      checker.fetch_upstream
      expect(URI).to have_received(:parse).with(RubyChecker::RUBY_INDEX_URL)
    end

    it 'returns latest version and sha256 keyed by major.minor' do
      result = checker.fetch_upstream
      expect(result['3.3']).to eq({ version: '3.3.10', sha256: 'newsha_xz' })
      expect(result['3.4']).to eq({ version: '3.4.2', sha256: 'sha34' })
    end

    it 'excludes non-xz entries (e.g. tar.gz)' do
      # ruby-3.3.9.tar.gz in the index has sha 'oldsha'; only .tar.xz lines count
      result = checker.fetch_upstream
      expect(result.values.map { |v| v[:sha256] }).not_to include('oldsha')
    end

    context 'with multi-digit minor and major version numbers' do
      let(:ruby_index) do
        <<~INDEX
          ruby-3.10.0\thttps://example.com/ruby-3.10.0.tar.xz\t000\tsha310\n
          ruby-10.0.0\thttps://example.com/ruby-10.0.0.tar.xz\t111\tsha100\n
        INDEX
      end

      it 'parses multi-digit minor versions' do
        expect(checker.fetch_upstream['3.10']).to eq({ version: '3.10.0', sha256: 'sha310' })
      end

      it 'parses multi-digit major versions' do
        expect(checker.fetch_upstream['10.0']).to eq({ version: '10.0.0', sha256: 'sha100' })
      end
    end

    context 'when sha field has surrounding whitespace' do
      let(:ruby_index) do
        "ruby-3.3.9\thttps://example.com/ruby-3.3.9.tar.xz\t456\t  sha_padded  \n"
      end

      it 'strips leading and trailing whitespace from sha256' do
        expect(checker.fetch_upstream['3.3'][:sha256]).to eq('sha_padded')
      end
    end

    context 'when the index contains a line that does not match the xz filter' do
      let(:ruby_index) do
        "ruby-3.5.0\thttps://example.com/ruby-3.5.0.tar.gz\t000\tgz_only_sha\n"
      end

      it 'excludes that series from results entirely' do
        expect(checker.fetch_upstream).not_to have_key('3.5')
      end
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

    it 'raises KeyError when ruby_version is missing from a version config' do
      manifest['ruby']['versions']['3.3'].delete('ruby_version')
      expect { checker.check(manifest) }.to raise_error(KeyError)
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

    context 'when sha256 contains a regex metacharacter' do
      let(:ruby_index) do
        <<~INDEX
          ruby-3.3.9\thttps://example.com/ruby-3.3.9.tar.xz\t456\tsha+xz
          ruby-3.3.10\thttps://example.com/ruby-3.3.10.tar.xz\t789\tnewsha
        INDEX
      end
      let(:manifest) do
        { 'ruby' => { 'versions' => {
          '3.3' => { 'ruby_version' => '3.3.9', 'ruby_download_sha256' => 'sha+xz' }
        } } }
      end

      it 'escapes the sha in the replacement pattern so apply! succeeds' do
        content = +"    ruby_version: 3.3.9\n    ruby_download_sha256: sha+xz"
        updates = checker.check(manifest)
        checker.apply!(content, updates)
        expect(content).to include('ruby_download_sha256: newsha')
      end
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
