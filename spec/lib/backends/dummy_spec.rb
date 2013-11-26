require 'spec_helper'

describe Backends::DummyBackend do
  let(:dummy) { Backends::DummyBackend.new nil, nil, nil, nil }
  let(:dummy_w_opts) {
    opts = Hashie::Mash.new
    opts.fixtures_dir = Rails.root.join('etc', 'backends', 'dummy', 'fixtures')
    Backends::DummyBackend.new nil, opts, nil, nil
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

    describe '#os_tpl_get' do
      it 'returns an Occi::Core::Mixin instance' do
        expect(dummy_w_opts.os_tpl_get(dummy_w_opts.os_tpl_list.first.term)).to be_kind_of(Occi::Core::Mixin)
      end

      it 'returns nil when such mixin does not exist' do
        expect(dummy_w_opts.os_tpl_get('my_dummy_non_existent')).to be_nil
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

    describe '#resource_tpl_get' do
      it 'returns an Occi::Core::Mixin instance' do
        expect(dummy_w_opts.resource_tpl_get(dummy_w_opts.resource_tpl_list.first.term)).to be_kind_of(Occi::Core::Mixin)
      end

      it 'returns nil when such mixin does not exist' do
        expect(dummy_w_opts.resource_tpl_get('my_dummy_non_existent')).to be_nil
      end
    end
  end
end