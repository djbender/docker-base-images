require_relative '../site/site_manifest'

RSpec.describe SiteManifest do
  # Reset memoized state between tests
  before do
    %i[@registry @image_types @manifest @globals @global_defaults].each do |ivar|
      described_class.instance_variable_set(ivar, nil)
    end
  end

  describe '.registry' do
    it 'returns the registry string' do
      expect(described_class.registry).to eq('ghcr.io/djbender')
    end
  end

  describe '.image_types' do
    it 'returns an array of ImageType objects' do
      types = described_class.image_types

      expect(types).to all(be_a(SiteManifest::ImageType))
    end

    it 'includes core, node, and ruby' do
      names = described_class.image_types.map(&:name)

      expect(names).to contain_exactly('core', 'node', 'ruby')
    end
  end

  describe '.image_type' do
    it 'returns an ImageType for a valid name' do
      type = described_class.image_type('ruby')

      expect(type).to be_a(SiteManifest::ImageType)
      expect(type.name).to eq('ruby')
    end

    it 'accepts symbol names' do
      type = described_class.image_type(:core)

      expect(type.name).to eq('core')
    end

    it 'raises for unknown image types' do
      expect { described_class.image_type('unknown') }.to raise_error(KeyError)
    end

    it 'interpolates %<registry>s in string values' do
      type = described_class.image_type('ruby')
      version = type.versions.first

      base_image = version.attrs['base_image']

      expect(base_image).not_to include('%<registry>s')
      expect(base_image).to include('ghcr.io/djbender')
    end

    it 'merges global defaults into version attrs' do
      type = described_class.image_type('core')
      version = type.versions.first

      expect(version.attrs).to have_key('platforms')
    end

    it 'merges image-level defaults into version attrs' do
      type = described_class.image_type('ruby')
      version = type.versions.first

      expect(version.attrs).to have_key('bundler_version')
    end
  end

  describe SiteManifest::ImageType do
    let(:image_type) { described_class.new('ruby', versions) }
    let(:versions) do
      [
        SiteManifest::ImageType::Version.new('3.3', { 'version' => '3.3' }),
        SiteManifest::ImageType::Version.new('4.0', { 'version' => '4.0', 'latest' => true })
      ]
    end

    describe '#latest_version' do
      it 'returns the version marked latest' do
        expect(image_type.latest_version.key).to eq('4.0')
      end

      it 'falls back to last version when none marked latest' do
        no_latest = [
          SiteManifest::ImageType::Version.new('3.3', { 'version' => '3.3' }),
          SiteManifest::ImageType::Version.new('3.4', { 'version' => '3.4' })
        ]
        type = described_class.new('ruby', no_latest)

        expect(type.latest_version.key).to eq('3.4')
      end
    end
  end

  describe SiteManifest::ImageType::Version do
    let(:registry) { 'ghcr.io/djbender' }

    around do |example|
      original_sha = ENV.fetch('GITHUB_SHA', nil)
      ENV.delete('GITHUB_SHA')
      example.run
      ENV['GITHUB_SHA'] = original_sha
    end

    context 'with ruby version' do
      let(:version) do
        described_class.new('3.3', {
                              'version' => '3.3',
                              'ruby_version' => '3.3.0',
                              'ruby_major' => '3.3',
                              'distribution_code_name' => 'noble'
                            })
      end

      it 'generates primary tags via TagGenerator' do
        expect(version.primary_tags).to include("#{registry}/ruby:3.3.0")
      end

      it 'generates dev tags via TagGenerator' do
        expect(version.dev_tags).to include("#{registry}/ruby:3.3-dev")
      end
    end

    context 'with node version' do
      let(:version) do
        described_class.new('22', {
                              'version' => '22',
                              'node_version' => '22.1.0',
                              'node_major' => '22',
                              'distribution_code_name' => 'noble'
                            })
      end

      it 'detects image type as node' do
        expect(version.primary_tags).to include("#{registry}/node:22.1.0")
      end
    end

    context 'with core version' do
      let(:version) do
        described_class.new('noble', {
                              'version' => 'noble',
                              'distribution_code_name' => 'noble'
                            })
      end

      it 'detects image type as core' do
        expect(version.primary_tags).to include("#{registry}/core:noble")
      end

      it 'generates core dev tags' do
        expect(version.dev_tags).to include("#{registry}/core:noble-dev")
      end
    end
  end
end
