require_relative '../lib/node_checker'

RSpec.describe NodeChecker do
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
      manifest['node']['versions']['99'] = {
        'node_version' => '99.0.0', 'npm_version' => '1.0.0'
      }
      updates = checker.check(manifest)

      expect(updates.map(&:key)).not_to include('99')
    end

    it 'uses regex replacement that captures whitespace' do
      update = checker.check(manifest).first
      pattern, replacement = update.replacements.first

      expect(pattern).to be_a(Regexp)
      expect(pattern).to match("node_version: 22.4.0\n      npm_version: 10.8.0")
      expect(replacement).to include('node_version: 22.5.0')
      expect(replacement).to include('npm_version: 10.9.0')
    end

    it 'does not collide when multiple versions share npm_version' do
      manifest['node']['versions']['20']['npm_version'] = '10.8.0'
      manifest['node']['versions']['20']['node_version'] = '20.17.0'

      content = +[
        '      node_version: 22.4.0',
        '      npm_version: 10.8.0',
        '      node_version: 20.17.0',
        '      npm_version: 10.8.0'
      ].join("\n")
      updates = checker.check(manifest)
      checker.apply!(content, updates)

      expect(content).to include("node_version: 22.5.0\n      npm_version: 10.9.0")
      expect(content).to include("node_version: 20.18.0\n      npm_version: 10.8.2")
    end
  end

  describe '#apply!' do
    it 'updates manifest content preserving indentation' do
      content = +[
        '      node_version: 22.4.0',
        '      npm_version: 10.8.0',
        '      node_version: 20.18.0',
        '      npm_version: 10.8.2'
      ].join("\n")
      updates = checker.check(manifest)

      checker.apply!(content, updates)
      expect(content).to include("node_version: 22.5.0\n      npm_version: 10.9.0")
      expect(content).to include("node_version: 20.18.0\n      npm_version: 10.8.2")
    end

    it 'preserves varying indentation' do
      content = +"    node_version: 22.4.0\n    npm_version: 10.8.0"
      updates = checker.check(manifest)

      checker.apply!(content, updates)
      expect(content).to eq("    node_version: 22.5.0\n    npm_version: 10.9.0")
    end
  end
end
