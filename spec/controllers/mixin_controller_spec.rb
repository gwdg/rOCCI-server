require 'spec_helper'

describe MixinController do

  describe "GET 'index'" do

    it 'returns http not implemented' do
      get 'index', term: 'test/my_mixin/', format: :uri_list
      expect(response.status).to eq 501
    end

  end

  describe "POST 'assign'" do

    it 'returns http not implemented' do
      post 'assign', term: 'test/my_mixin/', format: :text
      expect(response.status).to eq 501
    end

  end

  describe "POST 'trigger'" do

    it 'returns http not implemented' do
      post 'trigger', term: 'test/my_mixin/', format: :text
      expect(response.status).to eq 501
    end

  end

  describe "PUT 'update'" do

    it 'returns http not implemented' do
      put 'update', term: 'test/my_mixin/', format: :text
      expect(response.status).to eq 501
    end

  end

  describe "DELETE 'delete'" do

    it 'returns http not implemented' do
      delete 'delete', term: 'test/my_mixin/', format: :text
      expect(response.status).to eq 501
    end

  end

end
