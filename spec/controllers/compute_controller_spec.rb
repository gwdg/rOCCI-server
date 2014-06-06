require 'spec_helper'

describe ComputeController do

  describe "GET 'index'" do

    it 'returns http success' do
      get 'index', format: :uri_list
      expect(response).to be_success
    end

    it 'returns an array by default' do
      get 'index', format: '*/*'
      expect(assigns(:computes)).to be_kind_of(Array)
    end

    it 'returns a collection for text/html' do
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

    it 'returns an array with instances by default' do
      get 'index', format: '*/*'
      expect(assigns(:computes)).not_to be_empty
    end

    it 'returns a collection with instances for text/html' do
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

  describe "POST 'create'" do

    let(:fake_app) { Proc.new {} }
    let(:body) {
      %Q|Category: compute;scheme="http://schemas.ogf.org/occi/infrastructure#";class="kind"
X-OCCI-Attribute: occi.core.id="0444ecfc-a518-47a4-b5ca-c9a7320ecccc"
X-OCCI-Attribute: occi.core.title="Compute1"
X-OCCI-Attribute: occi.core.summary="Scientific Linux 6.2 Boron"
X-OCCI-Attribute: occi.compute.hostname="compute1.example.org"|
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
      expect(response.body).to include('http://localhost:3000/compute/0444ecfc-a518-47a4-b5ca-c9a7320ecccc')
    end

  end

  # TODO: impl
  describe "POST 'trigger'"

  describe "POST 'partial_update'" do

    it 'return http 501 not implemented' do
      post 'partial_update', format: :text, id: '87f3bfc3-42d4-4474-b45c-757e55e093e9'
      expect(response.status).to eq 501
    end

  end

  describe "PUT 'update'" do

    let(:fake_app) { Proc.new {} }
    let(:body) {
      %Q|Category: compute;scheme="http://schemas.ogf.org/occi/infrastructure#";class="kind"
X-OCCI-Attribute: occi.core.id="87f3bfc3-42d4-4474-b45c-757e55e093e9"
X-OCCI-Attribute: occi.core.title="Compute1"
X-OCCI-Attribute: occi.core.summary="Scientific Linux 6.2 Boron"
X-OCCI-Attribute: occi.compute.hostname="compute1.example.org"|
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

      put 'update', format: :text, id: '87f3bfc3-42d4-4474-b45c-757e55e093e9'
      expect(response).to be_bad_request
    end

    it 'returns http bad request with invalid body' do
      setup_invl_fail

      put 'update', format: :text, id: '87f3bfc3-42d4-4474-b45c-757e55e093e9'
      expect(response).to be_bad_request
    end

    it 'returns http created on success' do
      setup_success

      put 'update', format: :text, id: '87f3bfc3-42d4-4474-b45c-757e55e093e9'
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
      delete 'delete', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      expect(response).to be_success
    end

    it 'removes an existing resource' do
      delete 'delete', id: '87f3bfc3-42d4-4474-b45c-757e55e093e9', format: :text
      expect(response).to be_success
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
      delete 'delete', format: :text
      expect(response).to be_success
    end

  end

end
