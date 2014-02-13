require 'spec_helper'

describe OcciModelController do

  pending "add some examples to (or delete) #{__FILE__}"

  describe "GET 'index'" do
    it 'returns http success' do
      @request.env['HTTP_ACCEPT'] = 'application/json'
      @request.env['CONTENT_TYPE'] = 'application/json'
      get 'index'
      expect(response).to be_success
    end
  end

end
