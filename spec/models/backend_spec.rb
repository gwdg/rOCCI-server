require 'spec_helper'

describe Backend do

  describe '#method_missing' do

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

  describe 'class attribute accessors' do

    it 'has a backend_class reader' do
      expect(Backend).to respond_to(:backend_class)
    end

    it 'has a backend_class writer' do
      expect(Backend).to respond_to(:backend_class=)
    end

    it 'has a options reader' do
      expect(Backend).to respond_to(:options)
    end

    it 'has a options writer' do
      expect(Backend).to respond_to(:options=)
    end

    it 'has a server_properties reader' do
      expect(Backend).to respond_to(:server_properties)
    end

    it 'has a server_properties writer' do
      expect(Backend).to respond_to(:server_properties=)
    end

  end

end
