require 'spec_helper'

describe CorsController do

  describe "GET 'index'" do

    it 'returns http success for text/uri-list' do
      get 'index', format: :uri_list
      expect(response).to be_success
    end

    it 'returns http success for text/plain' do
      get 'index', format: :text
      expect(response).to be_success
    end

    it 'returns http success for text/occi' do
      get 'index', format: :occi_header
      expect(response).to be_success
    end

    it 'returns http success for text/html' do
      get 'index', format: :html
      expect(response).to be_success
    end

    it 'returns http success for */*' do
      get 'index', format: '*/*'
      expect(response).to be_success
    end

    it 'returns http success for */*' do
      get 'index', format: '*/*'
      expect(response.body).to be_empty
    end

  end

end
