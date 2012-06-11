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

  describe "Model" do

    it "initializes Model Extensions successfully" do
      OCCI::Model.register_files('etc/model/extensions/', 'http://example.com')
      OCCI::Model.get_by_id('http://schemas.ogf.org/occi/infrastructure/compute#console').should be_kind_of OCCI::Core::Kind
    end

    it "initializes OpenNebula Model Extensions successfully" do
      OCCI::Model.register_files('etc/backend/opennebula/model/', 'http://example.com')
      OCCI::Model.get_by_id('http://opennebula.org/occi/infrastructure#compute').should be_kind_of OCCI::Core::Mixin
      OCCI::Model.get_by_id('http://opennebula.org/occi/infrastructure#storage').should be_kind_of OCCI::Core::Mixin
      OCCI::Model.get_by_id('http://opennebula.org/occi/infrastructure#storagelink').should be_kind_of OCCI::Core::Mixin
      OCCI::Model.get_by_id('http://opennebula.org/occi/infrastructure#network').should be_kind_of OCCI::Core::Mixin
      OCCI::Model.get_by_id('http://opennebula.org/occi/infrastructure#networkinterface').should be_kind_of OCCI::Core::Mixin
    end

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
      jj resource_template
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
      collection.mixins.should have_at_least(1).mixin
      os_template = collection.mixins.select { |mixin| mixin.term != "os_tpl" }.first
      jj os_template
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
      jj resource_template
      header "Category", %Q|os_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin""|
      get '/-/'
      last_response.should be_ok
      collection = Hashie::Mash.new(JSON.parse(last_response.body))
      collection.mixins.should have_at_least(1).mixin
      os_template = collection.mixins.select { |mixin| mixin.term != "os_tpl" }.first
      jj os_template
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
      action_location = collection.resources.first.links.first.target
      post action_location
      last_response.should be_http_ok
    end
  end

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

    it "creates a new storage resource with a request in plain text format" do
      sleep 2
      header "Accept", "text/uri-list"
      header "Content-type", "application/occi+json"
      body = %Q|{"resources":[{"attributes":{"occi":{"storage":{"size":2},"core":{"title":"My Image created in json format"}}},"kind":"http://schemas.ogf.org/occi/infrastructure#storage"}]}|
      post '/storage/', body
      last_response.should be_http_created
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
