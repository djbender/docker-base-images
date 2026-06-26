require_relative '../lib/generation_message'

RSpec.describe GenerationMessage do
  describe '#initialize' do
    it 'accepts no-arg construction' do
      expect { described_class.new }.not_to raise_error
    end

    it 'accepts a task_name argument' do
      expect { described_class.new('generate:ruby') }.not_to raise_error
    end

    it 'stores the task_name' do
      msg = described_class.new('generate:ruby')
      expect(msg.task_name).to eq('generate:ruby')
    end

    it 'defaults task_name to nil' do
      msg = described_class.new
      expect(msg.task_name).to be_nil
    end
  end

  describe '#render' do
    it 'includes the generation notice' do
      expect(described_class.new.render).to include('NOTICE: This is a generated file')
    end

    it 'includes the specific task name when provided' do
      msg = described_class.new('generate:ruby')
      expect(msg.render).to include('rake generate:ruby')
    end

    it 'falls back to rake generate:all when task_name is nil' do
      msg = described_class.new
      expect(msg.render).to include('rake generate:all')
    end
  end
end
