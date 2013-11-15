require 'spec_helper'

describe Backend do

  context '#method_missing' do

    it 'raises a MethodNotImplementedError' do
      expect { Backend.new.does_not_exist }.to raise_error(Errors::MethodNotImplementedError)
    end

    it 'raises an error with a message containing the method name' do
      begin
        Backend.new.does_not_exist
        expect(true).to be_false
      rescue Errors::MethodNotImplementedError => err
        expect(err.message).to include('does_not_exist')
      end
    end

  end

  context 'self.load_backend_class' do

    it 'raises a NameError for non-existent backend' do
      expect { Backend.load_backend_class 'nope' }.to raise_error(ArgumentError)
    end

    it 'returns matching backend class' do
      expect(Backend.load_backend_class 'dummy').to eq Backends::Dummy
    end

  end

  context 'self.check_version' do
    let(:backend_class_match) {
      backend_class = 'Backends::Test'.split('::').inject(Object) {|o,c| o.const_get c}
      backend_class.const_set('API_VERSION', Backend::API_VERSION)
      backend_class
    }
    let(:backend_class_nover) {
      backend_class = 'Backends::Test'.split('::').inject(Object) {|o,c| o.const_get c}
      backend_class
    }
    let(:backend_class_mismatch) {
      backend_class = 'Backends::Test'.split('::').inject(Object) {|o,c| o.const_get c}
      backend_class.const_set('API_VERSION', '666.666.666')
      backend_class
    }

    it 'reports missing API version' do
      expect { Backend.check_version(backend_class_nover) }.to raise_error(Errors::BackendApiVersionMissingError)
    end

    it 'fails on mismatch' do
      expect { Backend.check_version(backend_class_mismatch) }.to raise_error(Errors::BackendApiVersionMismatchError)
    end

    it 'reports success on match' do
      expect(Backend.check_version(backend_class_match)).to be_true
    end
  end

  context 'attribute accessors' do

    it 'has a backend_class reader' do
      expect(Backend.new).to respond_to(:backend_class)
    end

    it 'has a options reader' do
      expect(Backend.new).to respond_to(:options)
    end

    it 'has a server_properties reader' do
      expect(Backend.new).to respond_to(:server_properties)
    end

    it 'has a backend_name reader' do
      expect(Backend.new).to respond_to(:backend_name)
    end

  end

end
