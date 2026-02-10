require_relative '../lib/metadata'

RSpec.describe Metadata do
  let(:metadata) do
    described_class.new(
      'registry' => 'ghcr.io/djbender',
      'image_name' => 'core',
      'version' => 'jammy'
    )
  end

  describe '#initialize' do
    it 'creates accessor methods for each key' do
      metadata = described_class.new('foo' => 'bar', 'baz' => 123)

      expect(metadata.foo).to eq('bar')
      expect(metadata.baz).to eq(123)
    end

    it 'sets instance variables for each key' do
      metadata = described_class.new('version' => '1.0')

      expect(metadata.instance_variable_get(:@version)).to eq('1.0')
    end
  end

  describe '#get_binding' do
    it 'returns a binding for ERB evaluation' do
      metadata = described_class.new('name' => 'test')

      result = metadata.get_binding

      expect(result).to be_a(Binding)
    end

    it 'binding has access to instance variables' do
      metadata = described_class.new('version' => '2.0')

      result = metadata.get_binding.eval('@version')

      expect(result).to eq('2.0')
    end
  end

  describe '#full_image_path' do
    it 'returns ghcr.io/djbender/<image_name>' do
      metadata = described_class.new('image_name' => 'ruby')

      expect(metadata.full_image_path).to eq('ghcr.io/djbender/ruby')
    end
  end

  describe '#context_path' do
    it 'returns original_image_name/original_version' do
      metadata = described_class.new(
        'original_image_name' => 'ruby',
        'original_version' => '3.2'
      )

      expect(metadata.context_path).to eq('ruby/3.2')
    end
  end

  describe '#docker_tags' do
    it 'delegates to TagGenerator.primary_tags' do
      values = { 'version' => '3.2' }
      metadata = described_class.new(values.merge('image_name' => 'ruby'))

      allow(TagGenerator).to receive(:primary_tags).and_return(['ruby:3.2'])

      result = metadata.docker_tags

      expect(TagGenerator).to have_received(:primary_tags).with('ruby', values.merge('image_name' => 'ruby'))
      expect(result).to eq(['ruby:3.2'])
    end
  end

  describe '#docker_dev_tags' do
    it 'delegates to TagGenerator.dev_tags' do
      values = { 'version' => '3.2' }
      metadata = described_class.new(values.merge('image_name' => 'ruby'))

      allow(TagGenerator).to receive(:dev_tags).and_return(['ruby:3.2-dev'])

      result = metadata.docker_dev_tags

      expect(TagGenerator).to have_received(:dev_tags).with('ruby', values.merge('image_name' => 'ruby'))
      expect(result).to eq(['ruby:3.2-dev'])
    end
  end

  describe '#cache_from' do
    it 'returns array with cache ref and image ref' do
      expect(metadata.cache_from).to eq [
        'type=registry,ref=ghcr.io/djbender/core:cache-jammy',
        'type=registry,ref=ghcr.io/djbender/core:jammy'
      ]
    end
  end

  describe '#cache_to' do
    it 'returns single-element array with mode=max' do
      expect(metadata.cache_to).to eq [
        'type=registry,ref=ghcr.io/djbender/core:cache-jammy,mode=max'
      ]
    end
  end

  describe '#cache_from_dev' do
    it 'returns array with dev cache ref and dev image ref' do
      expect(metadata.cache_from_dev).to eq [
        'type=registry,ref=ghcr.io/djbender/core:cache-dev-jammy',
        'type=registry,ref=ghcr.io/djbender/core:dev-jammy'
      ]
    end
  end

  describe '#cache_to_dev' do
    it 'returns single-element array with dev mode=max' do
      expect(metadata.cache_to_dev).to eq [
        'type=registry,ref=ghcr.io/djbender/core:cache-dev-jammy,mode=max'
      ]
    end
  end

  describe '#branch_suffix' do
    around do |example|
      original = ENV.fetch('GITHUB_REF_NAME', nil)
      example.run
      ENV['GITHUB_REF_NAME'] = original
    end

    it 'returns empty string for main branch' do
      ENV['GITHUB_REF_NAME'] = 'main'
      metadata = described_class.new({})

      expect(metadata.branch_suffix).to eq('')
    end

    it 'returns empty string when GITHUB_REF_NAME not set' do
      ENV.delete('GITHUB_REF_NAME')
      metadata = described_class.new({})

      expect(metadata.branch_suffix).to eq('')
    end

    it 'returns -branchname for feature branches' do
      ENV['GITHUB_REF_NAME'] = 'feature-branch'
      metadata = described_class.new({})

      expect(metadata.branch_suffix).to eq('-feature-branch')
    end

    it 'sanitizes special characters in branch name' do
      ENV['GITHUB_REF_NAME'] = 'feature/foo@bar'
      metadata = described_class.new({})

      expect(metadata.branch_suffix).to eq('-feature-foo-bar')
    end
  end

  describe '#method_missing' do
    it 'returns nil for undefined methods' do
      metadata = described_class.new({})

      expect(metadata.undefined_method).to be_nil
    end

    it 'returns nil even with arguments' do
      metadata = described_class.new({})

      expect(metadata.undefined_method('arg1', 'arg2')).to be_nil
    end
  end

  describe '#respond_to_missing?' do
    it 'returns nil for undefined methods' do
      metadata = described_class.new({})

      # respond_to_missing? returns nil (signature mismatch in impl, but call directly)
      expect(metadata.send(:respond_to_missing?, :undefined_method)).to be_nil
    end

    it 'returns true for defined dynamic methods via respond_to?' do
      metadata = described_class.new('defined_key' => 'value')

      expect(metadata.respond_to?(:defined_key)).to be true
    end
  end
end
