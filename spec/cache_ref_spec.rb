require 'spec_helper'
require_relative '../lib/cache_ref'

RSpec.describe CacheRef do
  describe '.from' do
    it 'builds cache-from ref string' do
      result = described_class.from('ghcr.io/djbender/core', 'jammy')
      expect(result).to eq('type=registry,ref=ghcr.io/djbender/core:cache-jammy')
    end

    it 'handles dev tags' do
      result = described_class.from('ghcr.io/djbender/ruby', 'dev-3.3')
      expect(result).to eq('type=registry,ref=ghcr.io/djbender/ruby:cache-dev-3.3')
    end
  end

  describe '.fallback' do
    it 'builds ref string without cache- prefix' do
      result = described_class.fallback('ghcr.io/djbender/core', 'jammy')
      expect(result).to eq('type=registry,ref=ghcr.io/djbender/core:jammy')
    end
  end

  describe '.to' do
    it 'builds cache-to ref string with mode=max' do
      result = described_class.to('ghcr.io/djbender/core', 'jammy')
      expect(result).to eq('type=registry,ref=ghcr.io/djbender/core:cache-jammy,mode=max')
    end

    it 'handles dev tags' do
      result = described_class.to('ghcr.io/djbender/ruby', 'dev-3.3')
      expect(result).to eq('type=registry,ref=ghcr.io/djbender/ruby:cache-dev-3.3,mode=max')
    end
  end
end
