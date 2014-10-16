require 'spec_helper'

describe Backends::DummyBackend do
  let(:dalli) { Dalli::Client.new }
  let(:dummy_w_opts) do
    opts = Hashie::Mash.new
    opts.fixtures_dir = Rails.application.config.rocci_server_etc_dir.join('backends', 'dummy', 'fixtures')
    Backends::DummyBackend.new nil, opts, nil, nil, dalli
  end

  before(:each) { dalli.flush }
  after(:all) { Dalli::Client.new.flush }

  describe '#new' do
    it 'fails to instantiate without a fixtures_dir' do
      expect { Backends::DummyBackend.new nil, nil, nil, nil, dalli }.to raise_error
    end
  end

  context 'os_tpl_*' do
    describe '#os_tpl_list' do
      it 'returns an Occi::Core::Mixins instance' do
        expect(dummy_w_opts.os_tpl_list).to be_kind_of(Occi::Core::Mixins)
      end

      it 'returns a non-empty collection' do\
        expect(dummy_w_opts.os_tpl_list).not_to be_empty
      end
    end

    describe '#os_tpl_get' do
      it 'returns an Occi::Core::Mixin instance' do
        expect(dummy_w_opts.os_tpl_get(dummy_w_opts.os_tpl_list.first.term)).to be_kind_of(Occi::Core::Mixin)
      end

      it 'raises an error when such mixin does not exist' do
        expect { dummy_w_opts.os_tpl_get('my_dummy_non_existent') }.to raise_error
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
    end

    describe '#resource_tpl_get' do
      it 'returns an Occi::Core::Mixin instance' do
        expect(dummy_w_opts.resource_tpl_get(dummy_w_opts.resource_tpl_list.first.term)).to be_kind_of(Occi::Core::Mixin)
      end

      it 'raises an error when such mixin does not exist' do
        expect { dummy_w_opts.resource_tpl_get('my_dummy_non_existent') }.to raise_error
      end
    end
  end
end
