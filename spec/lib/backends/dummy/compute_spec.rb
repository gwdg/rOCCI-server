require 'spec_helper'

describe Backends::Dummy::Compute do
  let(:dalli) { Dalli::Client.new }
  let(:dummy_w_opts) do
    opts = Hashie::Mash.new
    opts.fixtures_dir = Rails.application.config.rocci_server_etc_dir.join('backends', 'dummy', 'fixtures')
    Backends::Dummy::Compute.new nil, opts, nil, nil, dalli
  end

  before(:each) { dalli.flush }
  after(:all) { Dalli::Client.new.flush }

  describe '#new' do
    it 'fails to instantiate without a fixtures_dir' do
      expect { Backends::Dummy::Compute.new nil, nil, nil, nil, dalli }.to raise_error
    end
  end

  context '*_os_tpl' do
    describe '#list_os_tpl' do
      it 'returns an Occi::Core::Mixins instance' do
        expect(dummy_w_opts.list_os_tpl).to be_kind_of(Occi::Core::Mixins)
      end

      it 'returns a non-empty collection' do\
        expect(dummy_w_opts.list_os_tpl).not_to be_empty
      end
    end

    describe '#get_os_tpl' do
      it 'returns an Occi::Core::Mixin instance' do
        expect(dummy_w_opts.get_os_tpl(dummy_w_opts.list_os_tpl.first.term)).to be_kind_of(Occi::Core::Mixin)
      end

      it 'raises an error when such mixin does not exist' do
        expect { dummy_w_opts.get_os_tpl('my_dummy_non_existent') }.to raise_error
      end
    end
  end

  context '*_resource_tpl' do
    describe '#list_resource_tpl' do
      it 'returns an Occi::Core::Mixins instance' do
        expect(dummy_w_opts.list_resource_tpl).to be_kind_of(Occi::Core::Mixins)
      end

      it 'returns a non-empty collection' do\
        expect(dummy_w_opts.list_resource_tpl).not_to be_empty
      end
    end

    describe '#get_resource_tpl' do
      it 'returns an Occi::Core::Mixin instance' do
        expect(dummy_w_opts.get_resource_tpl(dummy_w_opts.list_resource_tpl.first.term)).to be_kind_of(Occi::Core::Mixin)
      end

      it 'raises an error when such mixin does not exist' do
        expect { dummy_w_opts.get_resource_tpl('my_dummy_non_existent') }.to raise_error
      end
    end
  end
end
