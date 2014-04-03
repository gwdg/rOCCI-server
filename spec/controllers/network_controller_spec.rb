require 'spec_helper'

describe NetworkController do

  describe "GET 'index'" do

    it 'returns http success' do
      get 'index', format: :uri_list
      expect(response).to be_success
    end

    it 'returns a collection by default' do
      get 'index', format: :html
      expect(assigns(:networks)).to be_kind_of(Occi::Collection)
    end

    it 'returns an array for text/uri-list' do
      get 'index', format: :uri_list
      expect(assigns(:networks)).to be_kind_of(Array)
    end

    it 'returns a collection with instances by default' do
      get 'index', format: :html
      expect(assigns(:networks)).not_to be_empty
    end

    it 'returns an array with links for text/uri-list' do
      get 'index', format: :uri_list
      expect(assigns(:networks)).not_to be_empty
    end

    it 'returns an array with /network/ links for text/uri-list' do
      get 'index', format: :uri_list
      assigns(:networks).each { |nt| expect(nt).to include('/network/') }
    end

  end

  describe "GET 'show'" do

    it 'returns http success for existing resource' do
      get 'show', id: '23cd7d72-eb86-4036-8969-4c902014bbc6', format: :text
      expect(response).to be_success
    end

    it 'returns http not found for non-existing resource' do
      get 'show', id: '23cd7d72-eb86-4036-8969-4c902014bbc6FU', format: :text
      expect(response).to be_not_found
    end

    it 'returns http success for each listed resource' do
      get 'index', format: :uri_list
      assigns(:networks).each do |nt|
        get 'show', id: nt.split('/').last
        expect(response).to be_success
      end
    end

    it 'returns a collection' do
      get 'show', id: '23cd7d72-eb86-4036-8969-4c902014bbc6', format: :text
      expect(assigns(:network)).to be_kind_of(Occi::Collection)
    end

    it 'returns a collection with an instance' do
      get 'show', id: '23cd7d72-eb86-4036-8969-4c902014bbc6', format: :text
      expect(assigns(:network)).not_to be_empty
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

    it 'returns http success for removed resources' do
      delete 'delete', id: '23cd7d72-eb86-4036-8969-4c902014bbc6', format: :text
      expect(response).to be_success
    end

    it 'removes an existing resource' do
      delete 'delete', id: '23cd7d72-eb86-4036-8969-4c902014bbc6', format: :text
      expect(response).to be_success
    end

    it 'returns http not found for attempts to remove non-existing resource' do
      delete 'delete', id: '23cd7d72-eb86-4036-8969-4c902014bbc6FU', format: :text
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
