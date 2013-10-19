require 'spec_helper'

describe Backend do

  describe '#new' do

    context 'without a backend class' do
      before(:each) { Backend.backend_class = nil }
      after(:each) { Backend.backend_class = Backends::Dummy}

      it 'fails without a backend class' do
        expect { Backend.new }.to raise_error(Errors::BackendClassNotSetError) 
      end
    end

    context 'with an invalid backend class' do
      before(:each) { Backend.backend_class = 'not a class' }
      after(:each) { Backend.backend_class = Backends::Dummy}

      it 'fails with an invalid backend class' do
        expect { Backend.new }.to raise_error
      end
    end

    it 'succeedes without arguments' do
      expect { Backend.new }.not_to raise_error
    end

    it 'succeedes with the right number of arguments' do
      expect { Backend.new({}, {}, {}) }.not_to raise_error
    end

    it 'creates a backend instance' do
      expect { Backend.new.backend_instance }.not_to be_nil
    end

    it 'creates a backend instance of the right class' do
      expect(Backend.new.backend_instance.class).to eq(Backend.backend_class)
    end

    it 'creates a backend instance responding to #method_missing' do
      expect(Backend.new.backend_instance).to respond_to(:method_missing)
    end

  end

  describe '#method_missing' do

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

  describe 'attribute readers' do

    it 'has a backend_class reader' do
      expect(Backend.new).to respond_to(:backend_class)
    end

    it 'has a backend_instance reader' do
      expect(Backend.new).to respond_to(:backend_instance)
    end

    it 'has an options reader' do
      expect(Backend.new).to respond_to(:options)
    end

    it 'has a server_properties reader' do
      expect(Backend.new).to respond_to(:server_properties)
    end

    it 'does not have a credentials reader' do
      expect(Backend.new).not_to respond_to(:credentials)
    end

    it 'exposes frozen options' do
      expect(Backend.new.options.frozen?).to be_true
    end

    it 'exposes frozen server_properties' do
      expect(Backend.new.server_properties.frozen?).to be_true
    end

  end

  describe 'class attribute accessors' do

    it 'has a backend_class reader' do
      expect(Backend).to respond_to(:backend_class)
    end

    it 'has a backend_class writer' do
      expect(Backend).to respond_to(:backend_class=)
    end

  end

end
