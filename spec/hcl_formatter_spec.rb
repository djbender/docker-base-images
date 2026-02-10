require 'spec_helper'
require_relative '../lib/hcl_formatter'

RSpec.describe HclFormatter do
  subject(:formatter) { Object.new.extend(described_class) }

  describe '#hcl_list' do
    it 'formats single-element array inline' do
      expect(formatter.hcl_list(['one'])).to eq '["one"]'
    end

    it 'formats multi-element array with newlines' do
      expect(formatter.hcl_list(%w[a b])).to eq "[\n    \"a\",\n    \"b\"\n  ]"
    end
  end
end
