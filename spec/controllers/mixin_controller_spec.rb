require 'spec_helper'

describe MixinController do

  pending "add some examples to (or delete) #{__FILE__}"

  describe "GET 'index'" do
   it "returns http success" do
     get 'index', { term: 'my_stuff/test' }
     response.should be_success
   end
  end

end
