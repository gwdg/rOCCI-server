require 'spec_helper'

describe Backends::Dummy do
  let(:dummy) { Backends::Dummy.new nil, nil, nil, nil }
  let(:dummy_w_opts) {
    opts = Hashie::Mash.new
    opts.fixtures_dir = Rails.root.join('etc', 'backends', 'dummy', 'fixtures')
    Backends::Dummy.new nil, opts, nil, nil
  }

  context 'os_tpl_*' do
    describe '#os_tpl_list' do
      it 'returns an Occi::Core::Mixins instance' do
        expect(dummy_w_opts.os_tpl_list).to be_kind_of(Occi::Core::Mixins)
      end

      it 'returns a non-empty collection' do\
        expect(dummy_w_opts.os_tpl_list).not_to be_empty
      end

      it 'returns an empty collection without model_extensions_dir' do
        expect(dummy.os_tpl_list).to be_empty
      end
    end
  end

  context 'resource_tpl_*' do
    describe '#resource_tpl_list' do
      it 'returns an Occi::Core::Mixins instance' do
        expect(dummy_w_opts.resource_tpl_list).to be_kind_of(Occi::Core::Mixins)
      end

      it 'returns a non-empty collection' do\
        expect(dummy_w_opts.resource_tpl_list).not_to be_empty
      end

      it 'returns an empty collection without model_extensions_dir' do
        expect(dummy.resource_tpl_list).to be_empty
      end
    end
  end
end