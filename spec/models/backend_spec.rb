require 'spec_helper'

describe Backend do

  context '#method_missing' do

    it 'raises a MethodNotImplementedError' do
      expect { Backend.instance.does_not_exist }.to raise_error(Errors::MethodNotImplementedError)
    end

    it 'raises an error with a message containing the method name' do
      begin
        Backend.instance.does_not_exist
        expect(true).to be_false
      rescue Errors::MethodNotImplementedError => err
        expect(err.message).to include('does_not_exist')
      end
    end

  end

  context '#load_backend_class' do

    it 'raises a NameError for non-existent backend' do
      expect { Backend.load_backend_class 'nope' }.to raise_error(ArgumentError)
    end

    it 'returns matching backend class' do
      expect(Backend.load_backend_class 'dummy').to eq Backends::Dummy
    end

  end

  context 'attribute accessors' do

    it 'has a backend_class reader' do
      expect(Backend.instance).to respond_to(:backend_class)
    end

    it 'has a options reader' do
      expect(Backend.instance).to respond_to(:options)
    end

    it 'has a server_properties reader' do
      expect(Backend.instance).to respond_to(:server_properties)
    end

    it 'has a backend_name reader' do
      expect(Backend.instance).to respond_to(:backend_name)
    end

  end

end
