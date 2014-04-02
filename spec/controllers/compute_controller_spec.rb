require 'spec_helper'

describe ComputeController do

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

    it 'returns a collection with instances by default' do
      get 'index', format: :html
      expect(assigns(:computes)).not_to be_empty
    end

    it 'returns an array with links for text/uri-list' do
      get 'index', format: :uri_list
      expect(assigns(:computes)).not_to be_empty
    end

    it 'returns an array with /compute/ links for text/uri-list' do
      get 'index', format: :uri_list
      assigns(:computes).each { |cl| expect(cl).to include('/compute/') }
    end

  end

  describe "GET 'show'" do

    it 'returns http success for existing resource' do
      get 'show', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      expect(response).to be_success
    end

    it 'returns http not found for non-existing resource' do
      get 'show', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9FU', format: :text
      expect(response).to be_not_found
    end

    it 'returns http success for each listed resource' do
      get 'index', format: :uri_list
      assigns(:computes).each do |cl|
        get 'show', id: cl.split('/').last
        expect(response).to be_success
      end
    end

    it 'returns a collection' do
      get 'show', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      expect(assigns(:compute)).to be_kind_of(Occi::Collection)
    end

    it 'returns a collection with an instance' do
      get 'show', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      expect(assigns(:compute)).not_to be_empty
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
      delete 'delete', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      expect(response).to be_success
    end

    it 'removes an existing resource' do
      get 'show', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      expect(response).to be_success
      delete 'delete', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      get 'show', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      expect(response).to be_not_found
    end

    it 'returns http not found for attempts to remove non-existing resource' do
      delete 'delete', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9FU', format: :text
      expect(response).to be_not_found
    end

    it 'returns http success when removing all resources' do
      delete 'delete', format: :text
      expect(response).to be_success
    end

    it 'removes all existing resources' do
      get 'index'
      expect(assigns(:computes)).not_to be_empty
      delete 'delete', format: :text
      get 'index'
      expect(assigns(:computes)).to be_empty
    end

  end

end
