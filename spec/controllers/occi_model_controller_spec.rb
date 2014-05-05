require 'spec_helper'

describe OcciModelController do

  describe "GET 'index'" do

    # it 'returns http success with JSON' do
    #   get 'index', format: :occi_json
    #   expect(response).to be_success
    # end

    it 'returns http success with URI-LIST' do
      get 'index', format: :uri_list
      expect(response).to be_success
    end

    it 'returns http success with PLAIN' do
      get 'index', format: :text
      expect(response).to be_success
    end

    it 'returns http success with OCCI' do
      get 'index', format: :occi_header
      expect(response).to be_success
    end

  end

  describe "GET 'show'" do

    let(:fake_app) { Proc.new {} }
    before(:each){
      @request.env['rocci_server.request.parser'] ||= ::RequestParsers::OcciParser.new(fake_app)
      @request.env['rocci_server.request.parser'].call(@request.env)
    }

    # it 'returns http success with JSON' do
    #   get 'show', format: :occi_json
    #   expect(response).to be_success
    # end

    it 'returns http success with PLAIN' do
      get 'show', format: :text
      expect(response).to be_success
    end

    it 'returns http success with OCCI' do
      get 'show', format: :occi_header
      expect(response).to be_success
    end

  end

  describe "POST 'create'" do

    it 'returns http not implemented' do
      post 'create', format: :text
      expect(response.status).to eq 501
    end

  end

  describe "DELETE 'delete'" do

    it 'returns http not implemented' do
      delete 'delete', format: :text
      expect(response.status).to eq 501
    end

  end

end
