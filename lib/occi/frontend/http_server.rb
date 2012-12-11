require 'sinatra/base'
require 'sinatra/multi_route'
require 'sinatra/cross_origin'
require 'sinatra/respond_with'

require 'hashie/mash'

require 'occi'
require 'occi/exceptions'

require "occi/frontend/http/http_frontend"
require "occi/frontend/http/http_request"

module OCCI
  module Frontend
    class HttpServer < Sinatra::Base

      set :sessions, true
      set :views, File.dirname(__FILE__) + "/../../../views"
      enable :logging

      register Sinatra::MultiRoute
      register Sinatra::CrossOrigin
      register Sinatra::RespondWith

      enable :cross_origin

      def initialize(standalone = true)
        @frontend = OCCI::Frontend::Http::HttpFrontend.new()

        super()
      end

      # from sinatra master, fixing issue with halt and after filter
      # Dispatch a request with error handling.
      def dispatch!
        invoke do
          static! if settings.static? && (request.get? || request.head?)
          filter! :before
          route!
        end
      rescue ::Exception => boom
        invoke { handle_exception!(boom) }
      ensure
        filter! :after unless env['sinatra.static_file']
      end

      # ---------------------------------------------------------------------------------------------------------------------
      # tasks to be executed before the request is handled
      before do
        response['Accept'] = "application/occi+json,application/json,text/plain,text/uri-list,application/xml,text/xml,application/occi+xml"
        response['Server'] = "rOCCI/#{OCCI::Server::VERSION} OCCI/1.1"

        @_request = OCCI::Frontend::Http::HttpRequest.new(request)

        @frontend.server = self
        @frontend.before_execute @_request
      end

      after do
        @collection, @locations = @frontend.after_execute @_request
        @collection ||= OCCI::Collection.new
        @locations  ||= Array.new
        OCCI::Log.debug('### Rendering response ###')
        OCCI::Log.debug("### Collection : \n #{@collection.to_json}")
        respond_to do |f|
          f.txt { erb :collection, :locals => { :collection => @collection, :locations => @locations } }
          f.on('*/*') { erb :collection, :locals => { :collection => @collection, :locations => @locations } }
          f.on('text/occi') do
            response.header.merge! @collection.to_header if @locations.empty?
            response.header['X-OCCI-Location'] = @locations.join ',' if @locations.any?
            'OK'
          end
          # f.html { haml :collection, :locals => {:collection => @collection} }
          f.json { @collection.to_json }
          f.on('application/occi+json') { @collection.to_json }
          f.xml { XmlSimple.xml_out(@collection.as_json, 'RootName' => 'occi') }
          f.on('application/occi+xml') { @collection.to_xml(:root => "collection") }
          f.on('text/uri-list') { @locations.join("\n") }
        end
      end

      # discovery interface
      # returns all kinds, mixins and actions registered for the server
      get '/-/', '/.well-known/org/ogf/occi/-/' do
        @_request.params = params
        @frontend.dynamic_execute 'get', @_request
      end

      # Resource retrieval
      # -----------------------------------------------------------------------------------------------------------------------
      # GET request
      # returns entities either below a certain path or belonging to a certain kind or mixin
      get '*' do
        @_request.params = params
        @frontend.dynamic_execute 'get', @_request
      end

      # ---------------------------------------------------------------------------------------------------------------------
      # POST request
      post '/-/', '/.well-known/org/ogf/occi/-/' do
        @_request.params = params
        @frontend.dynamic_execute 'post', @_request
      end

      # Create an instance appropriate to category field and optionally link an instance to another one
      post '*' do
        @_request.params = params
        @frontend.dynamic_execute 'post', @_request
      end

      # ---------------------------------------------------------------------------------------------------------------------
      # PUT request
      put '*' do
        @_request.params = params
        @frontend.dynamic_execute 'put', @_request
      end

      # ---------------------------------------------------------------------------------------------------------------------
      # DELETE request
      delete '/-/', '/.well-known/org/ogf/occi/-/' do
        @_request.params = params
        @frontend.dynamic_execute 'delete', @_request
      end

      delete '*' do
        @_request.params = params
        @frontend.dynamic_execute 'delete', @_request
      end

      error do
        OCCI::Log.error(sinatra.error)
        'Sorry there was a nasty error - ' + env['sinatra.error'].name
      end
    end
  end
end