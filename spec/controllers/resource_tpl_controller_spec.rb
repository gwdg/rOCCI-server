require 'spec_helper'

describe ResourceTplController do

  pending "add some examples to (or delete) #{__FILE__}"

  describe "GET 'index'" do

    it 'returns http success' do
      get 'index', format: :uri_list
      expect(response).to be_success
    end

    it 'returns a collection by default' do
      get 'index', format: :html
      expect(assigns(:computes)).to be_kind_of(Occi::Collection)
    end

    it 'returns an array for text/uri-list' do
      get 'index', format: :uri_list
      expect(assigns(:computes)).to be_kind_of(Array)
    end

    it 'returns an array for text/plain' do
      get 'index', format: :text
      expect(assigns(:computes)).to be_kind_of(Array)
    end

    it 'returns an array for text/occi' do
      get 'index', format: :occi_header
      expect(assigns(:computes)).to be_kind_of(Array)
    end

    # it 'returns a collection with instances by default' do
    #   get 'index', format: :html
    #   expect(assigns(:computes)).not_to be_empty
    # end

    # it 'returns an array with links for text/uri-list' do
    #   get 'index', format: :uri_list
    #   expect(assigns(:computes)).not_to be_empty
    # end

    # it 'returns an array with /compute/ links for text/uri-list' do
    #   get 'index', format: :uri_list
    #   assigns(:computes).each { |cl| expect(cl).to include('/compute/') }
    # end

  end

end
