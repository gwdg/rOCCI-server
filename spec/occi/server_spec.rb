require 'rspec'
require 'rspec/http'
require 'rack/test'
require 'logger'
require 'json'
require 'uri'

require 'occi/server'
require 'occi/model'

VERSION_NUMBER=0.5

describe OCCI::Server do
  include Rack::Test::Methods

  def app
    OCCI::Server
  end

  describe "GET /-/" do

    it "returns registered categories in JSON format" do
      header "Accept", "application/occi+json"
      get '/-/'
      last_response.should be_ok
      collection = Hashie::Mash.new(JSON.parse(last_response.body))
      collection.kinds.should have_at_least(3).kinds
    end

    it "returns registered categories in plain text format " do
      header "Accept", "text/plain"
      get '/-/'
      last_response.should be_ok
      last_response.body.should include('Category')
    end

  end

  describe "POST /compute/" do
    it "creates a new compute resource with a request in plain text format" do
      header "Accept", "text/uri-list"
      header "Content-type", "text/plain"
      body = %Q{Category: compute; scheme="http://schemas.ogf.org/occi/infrastructure#"; class="kind"}
      body += %Q{\nX-OCCI-Attribute: occi.compute.cores=2}
      post '/compute/', body
      last_response.should be_http_created
    end

    it "creates a new compute resource with a request in json format" do
      header "Accept", "text/uri-list"
      header "Content-type", "application/occi+json"
      body = %Q|{"resources":[{"attributes":{"occi":{"compute":{"cores":2}}},"kind":"http://schemas.ogf.org/occi/infrastructure#compute"}]}|
      post '/compute/', body
      last_response.should be_http_created
    end

    it "creates a new compute resource with a resource template in json format" do
      header "Accept", "application/occi+json"
      header "Content-type", "text/occi"
      header "Category", %Q|resource_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin"|
      get '/-/'
      last_response.should be_ok
      collection = Hashie::Mash.new(JSON.parse(last_response.body))
      collection.mixins.should have_at_least(1).mixin
      resource_template = collection.mixins.select { |mixin| mixin.term != "resource_tpl" }.first
      header "Accept", "text/uri-list"
      header "Content-type", "application/occi+json"
      header "Category", ''
      body = %Q|{"resources":[{"kind":"http://schemas.ogf.org/occi/infrastructure#compute","mixins":["#{resource_template.scheme + resource_template.term}"]}]}|
      post '/compute/', body
      last_response.should be_http_created
    end

    it "creates a new compute resource with an OS template in json format" do
      header "Accept", "application/occi+json"
      header "Content-type", "text/occi"
      header "Category", %Q|os_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin"|
      get '/-/'
      last_response.should be_ok
      collection = Hashie::Mash.new(JSON.parse(last_response.body))
      collection.mixins.should have_at_least(2).mixins
      os_template = collection.mixins.select { |mixin| mixin.term != "os_tpl" }.first
      puts os_template
      header "Accept", "text/uri-list"
      header "Content-type", "application/occi+json"
      header "Category", ''
      body = %Q|{"resources":[{"kind":"http://schemas.ogf.org/occi/infrastructure#compute","mixins":["#{os_template.scheme + os_template.term}"]}]}|
      post '/compute/', body
      last_response.should be_http_created
    end

    it "creates a new compute resource with a resource and an OS template in json format" do
      header "Accept", "application/occi+json"
      header "Content-type", "text/occi"
      header "Category", %Q|resource_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin"|
      get '/-/'
      last_response.should be_ok
      collection = Hashie::Mash.new(JSON.parse(last_response.body))
      collection.mixins.should have_at_least(1).mixin
      resource_template = collection.mixins.select { |mixin| mixin.term != "resource_tpl" }.first
      header "Category", %Q|os_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin""|
      get '/-/'
      last_response.should be_ok
      collection = Hashie::Mash.new(JSON.parse(last_response.body))
      collection.mixins.should have_at_least(1).mixin
      os_template = collection.mixins.select { |mixin| mixin.term != "os_tpl" }.first
      header "Accept", "text/uri-list"
      header "Content-type", "application/occi+json"
      header "Category", ''
      body = %Q|{"resources":[{"kind":"http://schemas.ogf.org/occi/infrastructure#compute","mixins":["#{resource_template.scheme + resource_template.term}","#{os_template.scheme + os_template.term}"]}]}|
      post '/compute/', body
      last_response.should be_http_created
    end

  end

  describe "GET /compute/" do
    it "gets all compute resources" do
      sleep 10
      header "Accept", "text/uri-list"
      get '/compute/'
      last_response.should be_http_ok
      last_response.body.lines.count.should >= 4
    end
  end
  

  describe "GET /compute/$uuid" do
    it "gets specific compute resource in text/plain format" do
      header "Accept", "text/uri-list"
      get '/compute/'
      last_response.should be_http_ok
      location = URI.parse(last_response.body.lines.to_a.last)
      header "Accept", "text/plain"
      get location.path
      last_response.should be_http_ok
      last_response.body.should include('scheme="http://schemas.ogf.org/occi/infrastructure#"')
    end
  end

  describe "GET /compute/$uuid" do
    it "gets specific compute resource in application/occi+json format" do
      header "Accept", "text/uri-list"
      get '/compute/'
      last_response.should be_http_ok
      location = URI.parse(last_response.body.lines.to_a.last)
      header "Accept", "application/occi+json"
      get location.path
      last_response.should be_http_ok
      collection = Hashie::Mash.new(JSON.parse(last_response.body))
      collection.resources.first.kind.should == 'http://schemas.ogf.org/occi/infrastructure#compute'
    end
  end

  describe "POST /compute/$uuid?action=X" do
    it "triggers applicable action on a previously created compute resource" do
      header "Content-type", ''
      header "Accept", "text/uri-list"
      get '/compute/'
      last_response.should be_http_ok
      location = URI.parse(last_response.body.lines.to_a.last)
      header "Accept", "application/occi+json"
      for i in 1..120
        get location.path
        last_response.should be_http_ok
        collection = Hashie::Mash.new(JSON.parse(last_response.body))
        break if collection.resources.first.attributes.occi.compute.state == "active"
        sleep 1
      end
      resource = collection.resources.first
      resource.actions.should include 'http://schemas.ogf.org/occi/infrastructure/compute/action#stop'
      action_location = location.path + '?action=stop'
      post action_location
      last_response.should be_http_ok
      for i in 1..120
        get location.path
        last_response.should be_http_ok
        collection = Hashie::Mash.new(JSON.parse(last_response.body))
        resource = collection.resources.first
        break if resource.attributes.occi.compute.state == "inactive"
        sleep 1
      end
      resource.attributes.occi.compute.state.should == "inactive"
    end
  end

  ################################################################################
  # For CloudStack Testing, uncomment this testcase if you're testing CloudStack #
  ################################################################################

  # For CloudStack Testing, uncomment this testcase if you're testing CloudStack
  # 
  # describe "GET /network/" do
  #   it "gets all network resources" do
  #     sleep 10
  #     header "Accept", "text/uri-list"
  #     get '/network/'
  #     last_response.should be_http_ok
  #     last_response.body.lines.count.should >= 1
  #   end
  # end
  # 
  # describe "GET /network/$uuid" do
  #   it "gets specific network resource in application/occi+json format" do
  #     header "Accept", "text/uri-list"
  #     get '/network/'
  #     last_response.should be_http_ok
  #     location = URI.parse(last_response.body.lines.to_a.last)
  #     header "Accept", "application/occi+json"
  #     get location.path
  #     last_response.should be_http_ok
  #     collection = Hashie::Mash.new(JSON.parse(last_response.body))
  #     collection.resources.first.kind.should == 'http://schemas.ogf.org/occi/infrastructure#network'
  #   end
  # end

  # describe "POST /network/$uuid?action=X" do
  #   it "triggers applicable action on a previously existing network resource" do
  #     header "Content-type", ''
  #     header "Accept", "text/uri-list"
  #     get '/network/'
  #     last_response.should be_http_ok
  #     location = URI.parse(last_response.body.lines.to_a.last)
  #     header "Accept", "application/occi+json"
  #     for i in 1..120
  #       get location.path
  #       last_response.should be_http_ok
  #       collection = Hashie::Mash.new(JSON.parse(last_response.body))
  #       break if collection.resources.first.attributes.occi.network.state == "active"
  #       sleep 1
  #     end
  #     resource = collection.resources.first
  #     resource.actions.should include 'http://schemas.ogf.org/occi/infrastructure/network/action#restart'
  #     action_location = location.path + '?action=restart'
  #     post action_location
  #     last_response.should be_http_ok
  #   end
  # end 

  describe "POST /storage/" do
    it "creates a new storage resource with a request in plain text format" do
      sleep 2
      header "Accept", "text/uri-list"
      header "Content-type", "text/plain"
      body = %Q{Category: storage; scheme="http://schemas.ogf.org/occi/infrastructure#"; class="kind"}
      body += %Q{\nX-OCCI-Attribute: occi.storage.size=2}
      body += %Q{\nX-OCCI-Attribute: occi.core.title="My Image created in plain text format"}
      post '/storage/', body
      last_response.should be_http_created
    end

    it "creates a new storage resource with a request in json format" do
      sleep 2
      header "Accept", "text/uri-list"
      header "Content-type", "application/occi+json"
      body = %Q|{"resources":[{"attributes":{"occi":{"storage":{"size":2},"core":{"title":"My Image created in json format"}}},"kind":"http://schemas.ogf.org/occi/infrastructure#storage"}]}|
      post '/storage/', body
      last_response.should be_http_created
    end
  end

  ################################################################################
  # For CloudStack Testing, uncomment this testcase if you're testing CloudStack #
  ################################################################################
  
  # describe "POST /storage/$uuid?action=X" do
  #   it "triggers applicable action on a previously created storage resource" do
  #     header "Content-type", ''
  #     header "Accept", "text/uri-list"
  #     get '/storage/'
  #     last_response.should be_http_ok
  #     storage_location = URI.parse(last_response.body.lines.to_a.last)
  #     header "Accept", "application/occi+json"
  #     for i in 1..120
  #       get storage_location.path
  #       last_response.should be_http_ok
  #       collection = Hashie::Mash.new(JSON.parse(last_response.body))
  #       break if collection.resources.first.attributes.occi.storage.state == "ready"
  #       sleep 1
  #     end
  #     storage_resource = collection.resources.first
  #     storage_resource.actions.should include 'http://schemas.ogf.org/occi/infrastructure/storage/action#attach'

  #     header "Content-type", ''
  #     header "Accept", "text/uri-list"
  #     get '/compute/'
  #     last_response.should be_http_ok
  #     compute_location = URI.parse(last_response.body.lines.to_a.first)
  #     header "Accept", "application/occi+json"
  #     for i in 1..120
  #       get compute_location.path
  #       last_response.should be_http_ok
  #       collection = Hashie::Mash.new(JSON.parse(last_response.body))
  #       break if collection.resources.first.attributes.occi.compute.state == "active"
  #       sleep 1
  #     end
  #     compute_resource = collection.resources.first
  #     compute_resource.actions.should include 'http://schemas.ogf.org/occi/infrastructure/compute/action#stop'

  #     action_location = storage_location.path + '?action=attach'
  #     body = JSON.parse(%Q|{"resources":[{"attributes":{"occi":{"core":{"id":"#{compute_resource.attributes.occi.core.id}"}}},"kind":"http://schemas.ogf.org/occi/infrastructure#compute"}]}|)
  #     post action_location, body
  #     last_response.should be_http_ok
  #     for i in 1..120
  #       get storage_location.path
  #       last_response.should be_http_ok
  #       collection = Hashie::Mash.new(JSON.parse(last_response.body))
  #       resource = collection.resources.first
  #       break if resource.attributes.occi.storage.state == "attached"
  #       sleep 1
  #     end
  #     resource.attributes.occi.storage.state.should == "attached"
  #   end

  #   it "triggers applicable action on a previously created storage resource" do
  #     header "Content-type", ''
  #     header "Accept", "text/uri-list"
  #     get '/storage/'
  #     last_response.should be_http_ok
  #     storage_location = URI.parse(last_response.body.lines.to_a.last)
  #     header "Accept", "application/occi+json"
  #     for i in 1..120
  #       get storage_location.path
  #       last_response.should be_http_ok
  #       collection = Hashie::Mash.new(JSON.parse(last_response.body))
  #       break if collection.resources.first.attributes.occi.storage.state == "attached"
  #       sleep 1
  #     end
  #     storage_resource = collection.resources.first
  #     storage_resource.actions.should include 'http://schemas.ogf.org/occi/infrastructure/storage/action#detach'

  #     action_location = storage_location.path + '?action=detach'
  #     post action_location
  #     last_response.should be_http_ok
  #     for i in 1..120
  #       get storage_location.path
  #       last_response.should be_http_ok
  #       collection = Hashie::Mash.new(JSON.parse(last_response.body))
  #       resource = collection.resources.first
  #       break if resource.attributes.occi.storage.state == "ready"
  #       sleep 1
  #     end
  #     resource.attributes.occi.storage.state.should == "ready"
  #   end
  # end

  describe "DELETE /storage/" do
    it "deletes all storage resources" do
      sleep 5
      header "Content-type", ''
      delete '/storage/'
      last_response.should be_http_ok
      header "Accept", "text/uri-list"
      sleep 5
      get '/storage/'
      last_response.should be_http_ok
      last_response.body.strip.should be_empty
    end
  end

  describe "DELETE /compute/" do
    it "deletes all compute resources" do
      sleep 5
      header "Content-type", ''
      delete '/compute/'
      last_response.should be_http_ok
      header "Accept", "text/uri-list"
      sleep 5
      get '/compute/'
      last_response.should be_http_ok
      last_response.body.strip.should be_empty
    end
  end

  describe "DELETE /" do
    it "deletes all resources" do
      sleep 5
      header "Content-type", ''
      delete '/'
      last_response.should be_http_ok
      header "Accept", "text/uri-list"
      sleep 5
      get '/storage/'
      last_response.should be_http_ok
      puts "Body: #{last_response.body}"
      last_response.body.strip.should be_empty
    end
  end

end
