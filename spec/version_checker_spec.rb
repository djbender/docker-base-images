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
          replacements: { /node_version: 20\.0\.0/ => 'node_version: 20.1.0' }
        )
      ]

      checker.apply!(content, updates)
      expect(content).to eq('node_version: 20.1.0')
    end

    it 'raises when replacement does not match' do
      checker = RubyChecker.new
      content = +'unrelated content'
      updates = [
        VersionChecker::Update.new(
          key: '3.3', current: '3.3.9', latest: '3.3.10',
          replacements: { /ruby_version: 3\.3\.9/ => 'ruby_version: 3.3.10' }
        )
      ]

      expect { checker.apply!(content, updates) }.to raise_error(RuntimeError, /No match for ruby 3.3/)
    end
  end
end
