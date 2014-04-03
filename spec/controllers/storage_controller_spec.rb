require 'spec_helper'

describe StorageController do

  describe "GET 'index'" do

    it 'returns http success' do
      get 'index', format: :uri_list
      expect(response).to be_success
    end

    it 'returns a collection by default' do
      get 'index', format: :html
      expect(assigns(:storages)).to be_kind_of(Occi::Collection)
    end

    it 'returns an array for text/uri-list' do
      get 'index', format: :uri_list
      expect(assigns(:storages)).to be_kind_of(Array)
    end

    it 'returns a collection with instances by default' do
      get 'index', format: :html
      expect(assigns(:storages)).not_to be_empty
    end

    it 'returns an array with links for text/uri-list' do
      get 'index', format: :uri_list
      expect(assigns(:storages)).not_to be_empty
    end

    it 'returns an array with /storage/ links for text/uri-list' do
      get 'index', format: :uri_list
      assigns(:storages).each { |st| expect(st).to include('/storage/') }
    end

  end

  describe "GET 'show'" do

    it 'returns http success for existing resource' do
      get 'show', id: '63a14263-2671-4429-bcd0-6ba19177491f', format: :text
      expect(response).to be_success
    end

    it 'returns http not found for non-existing resource' do
      get 'show', id: '63a14263-2671-4429-bcd0-6ba19177491fFU', format: :text
      expect(response).to be_not_found
    end

    it 'returns http success for each listed resource' do
      get 'index', format: :uri_list
      assigns(:storages).each do |st|
        get 'show', id: st.split('/').last
        expect(response).to be_success
      end
    end

    it 'returns a collection' do
      get 'show', id: '63a14263-2671-4429-bcd0-6ba19177491f', format: :text
      expect(assigns(:storage)).to be_kind_of(Occi::Collection)
    end

    it 'returns a collection with an instance' do
      get 'show', id: '63a14263-2671-4429-bcd0-6ba19177491f', format: :text
      expect(assigns(:storage)).not_to be_empty
    end

  end

  # TODO: impl
  describe "POST 'create'" do

    it 'returns http bad request without body' #do
    #   @request.env['rocci_server.request.parser'] = ::RequestParsers::OcciParser.new
    #   post 'create', format: :text
    #   expect(response).to be_bad_request
    # end
    it 'returns http bad request with invalid body'
    it 'returns http created on success'
    it 'returns a link on success'

  end

  # TODO: impl
  describe "POST 'trigger'"

  # TODO: impl
  describe "POST 'partial_update'"

  # TODO: impl
  describe "PUT 'update'"

  describe "DELETE 'delete'" do

    let(:dalli) { Dalli::Client.new }

    before(:each) { dalli.flush }
    after(:all) { dalli.flush }

    it 'returns http success for removed resources' do
      delete 'delete', id: '63a14263-2671-4429-bcd0-6ba19177491f', format: :text
      expect(response).to be_success
    end

    it 'removes an existing resource' do
      delete 'delete', id: '63a14263-2671-4429-bcd0-6ba19177491f', format: :text
      expect(response).to be_success
    end

    it 'returns http not found for attempts to remove non-existing resource' do
      delete 'delete', id: '63a14263-2671-4429-bcd0-6ba19177491fFU', format: :text
      expect(response).to be_not_found
    end

    it 'returns http success when removing all resources' do
      delete 'delete', format: :text
      expect(response).to be_success
    end

    it 'removes all existing resources' do
      delete 'delete', format: :text
      expect(response).to be_success
    end

  end

end
