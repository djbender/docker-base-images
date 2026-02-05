require 'tmpdir'
require 'fileutils'
require_relative '../lib/util'

RSpec.describe Util do
  describe 'constants' do
    it 'defines PROJECT_DIR' do
      expect(described_class::PROJECT_DIR).to be_a(String)
      expect(File.directory?(described_class::PROJECT_DIR)).to be true
    end

    it 'defines PROJECT_PATHNAME' do
      expect(described_class::PROJECT_PATHNAME).to be_a(Pathname)
    end

    it 'defines BAKE_FILE' do
      expect(described_class::BAKE_FILE).to eq('docker-bake.hcl')
    end

    it 'defines MANIFEST as a Hash' do
      expect(described_class::MANIFEST).to be_a(Hash)
    end

    it 'defines REGISTRY' do
      expect(described_class::REGISTRY).to be_a(String)
      expect(described_class::REGISTRY).not_to be_empty
    end
  end

  describe '.build_output_path' do
    it 'joins parts with PROJECT_DIR' do
      result = described_class.build_output_path('ruby', '3.1')

      expect(result).to eq(File.join(described_class::PROJECT_DIR, 'ruby', '3.1'))
    end

    it 'handles single part' do
      result = described_class.build_output_path('core')

      expect(result).to eq(File.join(described_class::PROJECT_DIR, 'core'))
    end

    it 'handles no parts' do
      result = described_class.build_output_path

      expect(result).to eq(described_class::PROJECT_DIR)
    end
  end

  describe '.build_template_dir' do
    it 'returns image_name/template path' do
      result = described_class.build_template_dir('ruby')

      expect(result).to eq('ruby/template')
    end
  end

  describe '.with_clean_output_dir' do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      allow(described_class).to receive(:build_output_path) { |*parts| File.join(tmpdir, *parts) }
    end

    after { FileUtils.rm_rf(tmpdir) }

    it 'creates directory if it does not exist' do
      output_dir = nil
      described_class.with_clean_output_dir('new', 'path') do |dir|
        output_dir = dir
      end

      expect(File.directory?(output_dir)).to be true
    end

    it 'removes existing directory before recreating' do
      existing_dir = File.join(tmpdir, 'existing')
      FileUtils.mkdir_p(existing_dir)
      File.write(File.join(existing_dir, 'old_file.txt'), 'content')

      described_class.with_clean_output_dir('existing') do |dir|
        expect(File.exist?(File.join(dir, 'old_file.txt'))).to be false
      end
    end

    it 'yields the output directory path' do
      yielded_path = nil
      described_class.with_clean_output_dir('test', 'dir') do |dir|
        yielded_path = dir
      end

      expect(yielded_path).to eq(File.join(tmpdir, 'test', 'dir'))
    end

    it 'allows block to create files in directory' do
      described_class.with_clean_output_dir('output') do |dir|
        File.write(File.join(dir, 'new_file.txt'), 'new content')
      end

      expect(File.read(File.join(tmpdir, 'output', 'new_file.txt'))).to eq('new content')
    end
  end
end
