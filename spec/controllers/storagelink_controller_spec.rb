require 'spec_helper'

describe StoragelinkController do

  pending "add some examples to (or delete) #{__FILE__}"

  describe "GET 'show'" do

    it 'returns not found' do
      get 'show',  id: 'df45ad6f4adf-daf4d5f6a4d-adf54ad5f6ad'
      expect(response.status).to eq(404)
    end

  end

end
