require 'spec_helper'

describe OcciModel do
  let(:backend) { Backend.new }

  context 'self.get' do
    it 'returns Occi::Model' do
      expect(OcciModel.get(backend)).to be_kind_of(Occi::Model)
    end

    it 'return non-empty Occi::Model' do
      expect(OcciModel.get(backend)).not_to be_empty
    end

    it 'fails without a backend instance' do
      expect { OcciModel.get }.to raise_error(ArgumentError)
    end
  end

  context 'self.get_filtered' do
    it 'returns Occi::Model' do
      expect(OcciModel.get_filtered(backend, Occi::Collection.new)).to be_kind_of(Occi::Model)
    end

    it 'raises an exception without a filter' do
      expect { OcciModel.get_filtered(backend, nil) }.to raise_error(ArgumentError)
    end
  end

  context 'self.get_extensions' do
    it 'returns Occi::Collection' do
      expect(OcciModel.send(:get_extensions, backend)).to be_kind_of(Occi::Collection)
    end
  end

end
