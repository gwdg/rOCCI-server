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

    it 'returns an array for text/plain' do
      get 'index', format: :text
      expect(assigns(:networks)).to be_kind_of(Array)
    end

    it 'returns an array for text/occi' do
      get 'index', format: :occi_header
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

  describe "POST 'create'" do

    let(:fake_app) { Proc.new {} }
    let(:body) {
      %Q|Category: network;scheme="http://schemas.ogf.org/occi/infrastructure#";class="kind"
X-OCCI-Attribute: occi.core.id="0444ecfc-a518-47a4-b5ca-c9a7320ecccc"
X-OCCI-Attribute: occi.core.title="Network1"
X-OCCI-Attribute: occi.core.summary="Private subnet"
X-OCCI-Attribute: occi.network.vlan=609|
    }
    let(:body_invalid) { 'not OCCI' }

    let(:setup_success) do
      env = @request.env
      env['rack.input'] = StringIO.new(body)
      env['CONTENT_TYPE'] = 'text/plain'
      @request.env['rocci_server.request.parser'].call(env)
    end

    let(:setup_empty_fail) do
      env = @request.env
      env['rack.input'] = StringIO.new('')
      env['CONTENT_TYPE'] = 'text/plain'
      @request.env['rocci_server.request.parser'].call(env)
    end

    let(:setup_invl_fail) do
      env = @request.env
      env['rack.input'] = StringIO.new(body_invalid)
      env['CONTENT_TYPE'] = 'text/plain'
      @request.env['rocci_server.request.parser'].call(env)
    end

    before(:each){
      @request.env['rocci_server.request.parser'] ||= ::RequestParsers::OcciParser.new(fake_app)
    }

    it 'returns http bad request without body' do
      setup_empty_fail

      post 'create', format: :text
      expect(response).to be_bad_request
    end

    it 'returns http bad request with invalid body' do
      setup_invl_fail

      post 'create', format: :text
      expect(response).to be_bad_request
    end

    it 'returns http created on success' do
      setup_success

      post 'create', format: :text
      expect(response.status).to eq 201
    end

    it 'returns a link on success' do
      setup_success

      post 'create', format: :text
      expect(response.body).to include('http://localhost:3000/network/0444ecfc-a518-47a4-b5ca-c9a7320ecccc')
    end

  end

  # TODO: impl
  describe "POST 'trigger'"

  describe "POST 'partial_update'" do

    it 'return http 501 not implemented' do
      post 'partial_update', format: :text, id: '23cd7d72-eb86-4036-8969-4c902014bbc6'
      expect(response.status).to eq 501
    end

  end

  describe "PUT 'update'" do

    let(:fake_app) { Proc.new {} }
    let(:body) {
      %Q|Category: network;scheme="http://schemas.ogf.org/occi/infrastructure#";class="kind"
X-OCCI-Attribute: occi.core.id="23cd7d72-eb86-4036-8969-4c902014bbc6"
X-OCCI-Attribute: occi.core.title="Network1"
X-OCCI-Attribute: occi.core.summary="Private subnet"
X-OCCI-Attribute: occi.network.vlan=609|
    }
    let(:body_invalid) { 'not OCCI' }

    let(:setup_success) do
      env = @request.env
      env['rack.input'] = StringIO.new(body)
      env['CONTENT_TYPE'] = 'text/plain'
      @request.env['rocci_server.request.parser'].call(env)
    end

    let(:setup_empty_fail) do
      env = @request.env
      env['rack.input'] = StringIO.new('')
      env['CONTENT_TYPE'] = 'text/plain'
      @request.env['rocci_server.request.parser'].call(env)
    end

    let(:setup_invl_fail) do
      env = @request.env
      env['rack.input'] = StringIO.new(body_invalid)
      env['CONTENT_TYPE'] = 'text/plain'
      @request.env['rocci_server.request.parser'].call(env)
    end

    before(:each){
      @request.env['rocci_server.request.parser'] ||= ::RequestParsers::OcciParser.new(fake_app)
    }

    it 'returns http bad request without body' do
      setup_empty_fail

      put 'update', format: :text, id: '23cd7d72-eb86-4036-8969-4c902014bbc6'
      expect(response).to be_bad_request
    end

    it 'returns http bad request with invalid body' do
      setup_invl_fail

      put 'update', format: :text, id: '23cd7d72-eb86-4036-8969-4c902014bbc6'
      expect(response).to be_bad_request
    end

    it 'returns http created on success' do
      setup_success

      put 'update', format: :text, id: '23cd7d72-eb86-4036-8969-4c902014bbc6'
      expect(response).to be_success
    end

    it 'returns http not found on non-existing resource' do
      setup_success

      put 'update', format: :text, id: 'not_there'
      expect(response).to be_not_found
    end

  end

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
