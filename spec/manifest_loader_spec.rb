require_relative '../lib/manifest_loader'

RSpec.describe ManifestLoader do
  describe '.load' do
    it 'returns a Hash' do
      expect(described_class.load).to be_a(Hash)
    end

    it 'includes globals key' do
      expect(described_class.load).to have_key('globals')
    end

    it 'includes image type keys' do
      manifest = described_class.load

      expect(manifest).to have_key('core')
      expect(manifest).to have_key('ruby')
      expect(manifest).to have_key('node')
    end
  end

  describe '.registry' do
    it 'returns the registry string from globals' do
      expect(described_class.registry).to eq('ghcr.io/djbender')
    end
  end
end
