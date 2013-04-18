require 'rspec'
require 'rspec/http'
require 'logger'
require 'json'
require 'uri'

require 'occi/frontend/amqp_server'
require 'occi/server'
require 'occi/model'

require "hashie/mash"

VERSION_NUMBER=0.5

module Occi
  module Frontend
    describe OCCI::Frontend::AmqpServer do

      before(:each) do
        @server = OCCI::Frontend::AmqpServer.new(false, 'amqp.occi.http://localhost:9292/', true)
      end

      def create_metadata(type)
        metadata = Hashie::Mash.new
        metadata.routing_key  = "amqp.occi.http://localhost:9292/"
        metadata.content_type = "text/plain"
        metadata.type         = type
        metadata.reply_to     = ""
        metadata.message_id   = "test_it"

        metadata.headers           = Hashie::Mash.new
        metadata.headers.accept    = "application/occi+json"
        metadata.headers.path_info = "/-/"

        metadata.headers.auth          = Hashie::Mash.new
        metadata.headers.auth.type     = "not implemented"
        metadata.headers.auth.username = "user"
        metadata.headers.auth.password = "mypass"

        metadata
      end

      def last_response
        @server.response.generate_output
      end

      describe "GET /-/" do

        it "returns registered categories in JSON format" do

          metadata = create_metadata 'get'

          @server.parse_message(metadata, '')

          @server.response.status.should == 200

          collection = Hashie::Mash.new(JSON.parse(last_response))
          collection.kinds.should have_at_least(3).kinds
        end

        it "returns registered categories in plain text format " do

          metadata = create_metadata 'get'
          metadata.headers.accept = "text/plain"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          last_response.should include('Category')
        end

      end

      describe "POST /compute/" do

        it "creates a new compute resource with a request in plain text format" do
          metadata = create_metadata 'post'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept = "text/uri-list"
          metadata.content_type   = "text/plain"


          payload = %Q{Category: compute; scheme="http://schemas.ogf.org/occi/infrastructure#"; class="kind"}
          payload += %Q{\nX-OCCI-Attribute: occi.compute.cores=2}

          @server.parse_message(metadata, payload)
          @server.response.status.should == 201
        end

        it "creates a new compute resource with a request in json format" do
          metadata = create_metadata 'post'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept = "text/uri-list"
          metadata.content_type   = "application/occi+json"

          payload = %Q|{"resources":[{"attributes":{"occi":{"compute":{"cores":2}}},"kind":"http://schemas.ogf.org/occi/infrastructure#compute"}]}|

          @server.parse_message(metadata, payload)
          @server.response.status.should == 201
        end

        it "creates a new compute resource with a resource template in json format" do
          metadata = create_metadata 'get'

          metadata.headers.path_info = "/-/"
          metadata.headers.accept    = "application/occi+json"
          metadata.content_type      = "text/occi"
          metadata.headers.category  = %Q|resource_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin"|

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          collection = Hashie::Mash.new(JSON.parse(last_response))
          collection.mixins.should have_at_least(1).mixin

          resource_template = collection.mixins.select { |mixin| mixin.term != "resource_tpl" }.first
          puts resource_template

          metadata = create_metadata 'post'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept    = "text/uri-list"
          metadata.content_type      = "application/occi+json"

          payload = %Q|{"resources":[{"kind":"http://schemas.ogf.org/occi/infrastructure#compute","mixins":["#{resource_template.scheme + resource_template.term}"]}]}|

          @server.parse_message(metadata, payload)
          @server.response.status.should == 201
        end

        it "creates a new compute resource with an OS template in json format" do
          metadata = create_metadata 'get'

          metadata.headers.path_info = "/-/"
          metadata.headers.accept    = "application/occi+json"
          metadata.content_type      = "text/occi"
          metadata.headers.category  = %Q|os_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin"|

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          collection = Hashie::Mash.new(JSON.parse(last_response))
          collection.mixins.should have_at_least(2).mixin

          os_template = collection.mixins.select { |mixin| mixin.term != "os_tpl" }.first
          puts os_template

          metadata = create_metadata 'post'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept    = "text/uri-list"
          metadata.content_type      = "application/occi+json"

          payload = %Q|{"resources":[{"kind":"http://schemas.ogf.org/occi/infrastructure#compute","mixins":["#{os_template.scheme + os_template.term}"]}]}|

          @server.parse_message(metadata, payload)
          @server.response.status.should == 201
        end

        it "creates a new compute resource with a resource and an OS template in json format" do
          metadata = create_metadata 'get'

          metadata.headers.path_info = "/-/"
          metadata.headers.accept    = "application/occi+json"
          metadata.content_type      = "text/occi"
          metadata.headers.category  = %Q|resource_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin"|

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          collection = Hashie::Mash.new(JSON.parse(last_response))
          collection.mixins.should have_at_least(1).mixin

          resource_template = collection.mixins.select { |mixin| mixin.term != "resource_tpl" }.first
          puts resource_template

          metadata.headers.category  = %Q|os_tpl;scheme="http://schemas.ogf.org/occi/infrastructure#";class="mixin""|

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          collection = Hashie::Mash.new(JSON.parse(last_response))
          collection.mixins.should have_at_least(2).mixin

          os_template = collection.mixins.select { |mixin| mixin.term != "os_tpl" }.first
          puts os_template

          metadata = create_metadata 'post'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept    = "text/uri-list"
          metadata.content_type      = "application/occi+json"

          payload = %Q|{"resources":[{"kind":"http://schemas.ogf.org/occi/infrastructure#compute","mixins":["#{resource_template.scheme + resource_template.term}","#{os_template.scheme + os_template.term}"]}]}|

          @server.parse_message(metadata, payload)
          @server.response.status.should == 201
        end
      end

      describe "GET /compute/" do
        it "gets all compute resources" do
          sleep 5
          metadata = create_metadata 'get'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept    = "text/uri-list"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          last_response.lines.count.should >= 4
        end
      end

      describe "GET /compute/$uuid" do
        it "gets specific compute resource in text/plain format" do
          metadata = create_metadata 'get'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept    = "text/uri-list"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          location = URI.parse(last_response.lines.to_a.last)

          metadata.headers.path_info = location.path
          metadata.headers.accept    = "text/plain"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          last_response.should include('scheme="http://schemas.ogf.org/occi/infrastructure#"')
        end

        it "gets specific compute resource in application/occi+json format" do
          metadata = create_metadata 'get'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept    = "text/uri-list"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          location = URI.parse(last_response.lines.to_a.last)

          metadata.headers.path_info = location.path
          metadata.headers.accept    = "application/occi+json"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          collection = Hashie::Mash.new(JSON.parse(last_response))
          collection.resources.first.kind.should == 'http://schemas.ogf.org/occi/infrastructure#compute'
        end
      end

      describe "POST /compute/$uuid?action=X" do
        it "triggers applicable action on a previously created compute resource" do
          metadata = create_metadata 'get'

          metadata.headers.path_info = "/compute/"
          metadata.headers.accept    = "text/uri-list"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          location = URI.parse(last_response.lines.to_a.last)
          metadata.headers.accept    = "application/occi+json"
          metadata.headers.path_info = location.path

          for i in 1..120
            @server.parse_message(metadata, '')
            @server.response.status.should == 200

            collection = Hashie::Mash.new(JSON.parse(last_response))
            break if collection.resources.first.attributes.occi.compute.state == "active"
            sleep 0.01
          end

          resource = collection.resources.first
          resource.actions.should include 'http://schemas.ogf.org/occi/infrastructure/compute/action#stop'
          action_location = location.path + '?action=stop'

          metadata.type              = "post"
          metadata.headers.path_info = action_location

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          for i in 1..120
            metadata.type              = "get"
            metadata.headers.path_info = action_location

            @server.parse_message(metadata, '')
            @server.response.status.should be 200

            collection = Hashie::Mash.new(JSON.parse(last_response))
            resource = collection.resources.first
            break if resource.attributes.occi.compute.state == "inactive"
            sleep 0.01
          end
          resource.attributes.occi.compute.state.should == "inactive"
        end
      end

      describe "POST /storage/" do
        it "creates a new storage resource with a request in plain text format" do
          sleep 1
          metadata = create_metadata 'post'
          metadata.headers.accept    = "text/uri-list"
          metadata.headers.path_info = "/storage/"

          payload = %Q{Category: storage; scheme="http://schemas.ogf.org/occi/infrastructure#"; class="kind"}
          payload += %Q{\nX-OCCI-Attribute: occi.storage.size=2}
          payload += %Q{\nX-OCCI-Attribute: occi.core.title="My Image created in plain text format"}

          @server.parse_message(metadata, payload)
          @server.response.status.should == 201
        end

        it "creates a new storage resource with a request in json format" do
          sleep 1
          metadata = create_metadata 'post'
          metadata.headers.path_info = "/storage/"
          metadata.headers.accept    = "text/uri-list"
          metadata.content_type      = "application/occi+json"

          payload = %Q|{"resources":[{"attributes":{"occi":{"storage":{"size":2},"core":{"title":"My Image created in json format"}}},"kind":"http://schemas.ogf.org/occi/infrastructure#storage"}]}|

          @server.parse_message(metadata, payload)
          @server.response.status.should == 201
        end
      end

      describe "DELETE /compute/" do
        it "deletes all compute resources" do
          sleep 2

          metadata = create_metadata 'delete'
          metadata.headers.path_info = "/compute/"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          sleep 5
          metadata = create_metadata 'get'
          metadata.headers.accept    = "text/uri-list"
          metadata.headers.path_info = "/compute/"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200
          last_response.strip.should be_empty
        end
      end

      describe "DELETE /" do
        it "deletes all resources" do
          sleep 2

          metadata = create_metadata 'delete'
          metadata.headers.path_info = "/"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200

          sleep 5
          metadata = create_metadata 'get'
          metadata.headers.accept    = "text/uri-list"
          metadata.headers.path_info = "/storage/"

          @server.parse_message(metadata, '')
          @server.response.status.should == 200
          last_response.strip.should be_empty
        end
      end
    end
  end
end