require 'spec_helper'

describe Backends::Now::Network do
  let(:dalli) { Dalli::Client.new }
  before(:each) { dalli.flush }
  after(:all) { Dalli::Client.new.flush }

  let(:now_backend_delegated_user) do
    user = Hashie::Mash.new
    user.identity = 'now_test_user'
    user
  end

  let(:now_backend_instance) do
    options = YAML.load(ERB.new(File.read("#{Rails.root}/etc/backends/now/test.yml")).result)
    instance = Backends::Now::Network.new(now_backend_delegated_user, options, nil, nil, dalli)
    instance
  end

  describe '#new' do
    it 'ok' do
      expect(now_backend_instance).to be_instance_of(Backends::Now::Network)
    end
  end
end
