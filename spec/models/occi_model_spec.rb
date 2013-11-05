require 'spec_helper'

describe OcciModel do
  
  context 'self.get' do
    it 'returns Occi::Model' do
      expect(OcciModel.get).to be_kind_of(Occi::Model)
    end

    it 'return non-empty Occi::Model' do
      expect(OcciModel.get).not_to be_empty
    end
  end

  context 'self.get_filtered' do
    it 'returns Occi::Model' do
      expect(OcciModel.get_filtered(Occi::Collection.new)).to be_kind_of(Occi::Model)
    end

    it 'return non-empty Occi::Model' do
      expect(OcciModel.get_filtered(nil)).not_to be_empty
    end
  end

  context 'self.get_extensions' do
    it 'returns Occi::Collection' do
      expect(OcciModel.send(:get_extensions)).to be_kind_of(Occi::Collection)
    end
  end

end
