require 'spec_helper'

describe Backend do

  context '#method_missing' do

    it 'raises a NameError' do
      expect { Backend.new.does_not_exist }.to raise_error(NameError)
    end

    it 'raises an error with a message containing the word undefined' do
      begin
        Backend.new.does_not_exist
        expect(true).to be false
      rescue NameError => err
        expect(err.message).to include('undefined')
      end
    end

  end

  context '#get_extensions' do

    let(:backend_instance) { Backend.new }

    it 'returns an OCCI collection' do
      expect(backend_instance.get_extensions).to be_kind_of Occi::Collection
    end

    it 'returns an empty collection for default backend' do
      expect(backend_instance.get_extensions).to be_empty
    end

  end

  context 'self.load_backend_class' do

    it 'raises an ArgumentError for non-existent backend' do
      expect { Backend.load_backend_class('nope', 'compute') }.to raise_error(ArgumentError)
    end

    it 'returns matching backend class' do
      expect(Backend.load_backend_class('dummy', 'compute')).to eq Backends::Dummy::Compute
    end

    it 'returns an ArgumentError for non-existent backend type' do
      expect { Backend.load_backend_class('dummy', 'nope') }.to raise_error(ArgumentError)
    end

  end

  context 'self.check_version' do
    it 'reports missing API version' do
      expect { Backend.check_version('1.0.0', '') }.to raise_error(Errors::BackendApiVersionMismatchError)
    end

    it 'fails on mismatch' do
      expect { Backend.check_version('2.0', '1.0') }.to raise_error(Errors::BackendApiVersionMismatchError)
    end

    it 'reports success on minor mismatch' do
      expect(Backend.check_version('2.1', '2.0')).to be true
    end

    it 'reports success on match' do
      expect(Backend.check_version('2.1', '2.1')).to be true
    end
  end

  context 'self.dalli_instance_factory' do
    it 'fails without backend_name' do
      expect { Backend.dalli_instance_factory(nil) }.to raise_error(ArgumentError)
      expect { Backend.dalli_instance_factory('') }.to raise_error(ArgumentError)
    end

    it 'returns Dalli::Client instance' do
      expect(Backend.dalli_instance_factory('dummy')).to be_kind_of(Dalli::Client)
    end
  end

  context 'attribute accessors' do

    it 'has a options reader' do
      expect(Backend.new).to respond_to(:options)
    end

    it 'has a server_properties reader' do
      expect(Backend.new).to respond_to(:server_properties)
    end

  end

end
