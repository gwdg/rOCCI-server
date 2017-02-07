require 'spec_helper'

describe StoragelinkController do

  pending "add some examples to (or delete) #{__FILE__}"

  describe "GET 'show'" do

    it 'returns not found' do
      get 'show',  id: 'df45ad6f4adf-daf4d5f6a4d-adf54ad5f6ad'
      expect(response.status).to eq(404)
    end

  end

  describe "GET 'index'" do

    it 'returns list' do
      get 'index', format: :uri_list
      expect(response).to be_success
    end

    it 'returns an array by default' do
      get 'index', format: '*/*'
      expect(assigns(:sls)).to be_kind_of(Array)
    end

    it 'returns a collection for text/html' do
      get 'index', format: :html
      expect(assigns(:sls)).to be_kind_of(Occi::Collection)
    end

    it 'returns an array for text/uri-list' do
      get 'index', format: :uri_list
      expect(assigns(:sls)).to be_kind_of(Array)
    end

    it 'returns an array for text/plain' do
      get 'index', format: :text
      expect(assigns(:sls)).to be_kind_of(Array)
    end

    it 'returns an array for text/occi' do
      get 'index', format: :occi_header
      expect(assigns(:sls)).to be_kind_of(Array)
    end

  end

end
