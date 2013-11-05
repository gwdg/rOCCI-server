require 'spec_helper'

describe Backends::Dummy do
  let(:dummy) { Backends::Dummy.new }
  let(:dummy_w_opts) {
    opts = Hashie::Mash.new
    opts.model_extensions_dir = Rails.root.join('etc', 'backends', 'dummy', 'model')
    Backends::Dummy.new opts
  }

  context 'os_tpl_*' do
    describe '#os_tpl_get_all' do
      it 'returns an Occi::Collection' do
        expect(dummy_w_opts.os_tpl_get_all).to be_kind_of(Occi::Collection)
      end

      it 'returns a non-empty collection' do\
        expect(dummy_w_opts.os_tpl_get_all).not_to be_empty
      end

      it 'returns an empty collection without model_extensions_dir' do
        expect(dummy.os_tpl_get_all).to be_empty
      end
    end
  end

  context 'resource_tpl_*' do
    describe '#resource_tpl_get_all' do
      it 'returns an Occi::Collection' do
        expect(dummy_w_opts.resource_tpl_get_all).to be_kind_of(Occi::Collection)
      end

      it 'returns a non-empty collection' do\
        expect(dummy_w_opts.resource_tpl_get_all).not_to be_empty
      end

      it 'returns an empty collection without model_extensions_dir' do
        expect(dummy.resource_tpl_get_all).to be_empty
      end
    end
  end
end