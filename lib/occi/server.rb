require 'sinatra/base'
require 'sinatra/multi_route'
require 'sinatra/cross_origin'
require 'sinatra/respond_with'

require 'hashie/mash'

require 'occi'
require 'occi/exceptions'

Encoding.default_external = Encoding::UTF_8 if defined? Encoding
Encoding.default_internal = Encoding::UTF_8 if defined? Encoding

module OCCI
  class Server < Sinatra::Base

    set :sessions, true
    set :views, File.dirname(__FILE__) + "/../../views"
    enable :logging

    VERSION = "0.5.0-beta1"

    register Sinatra::MultiRoute
    register Sinatra::CrossOrigin
    register Sinatra::RespondWith

    enable cross_origin

    def initialize

      logger = Logger.new(STDERR)

      @log_subscriber = ActiveSupport::Notifications.subscribe("log") do |name, start, finish, id, payload|
        logger.log(payload[:level], payload[:message])
      end

      @model = OCCI::Model.new

      collection = Hashie::Mash.new(JSON.parse(File.read(File.dirname(__FILE__) + "/../../etc/backend/default.json")))
      backend    = collection.resources.first
      case backend.kind
        when 'http://rocci.info/server/backend#dummy'
          require 'occi/backend/dummy'
          @model.register(OCCI::Backend::Dummy.kind_definition)
          @backend = OCCI::Backend::Dummy.new(backend.kind, backend.mixins, backend.attributes, backend.links)
          @backend.check(@model)
          OCCI::Log.debug('Dummy backend initialized')
        #@backend = OCCI::Backend::Dummy.new(backend.kind,backend.mixins,backend.attributes,backend.links)
        when 'http://rocci.info/server/backend#opennebula'
          require 'occi/backend/opennebula'
          @model.register(OCCI::Backend::OpenNebula.kind_definition)
          @backend = OCCI::Backend::OpenNebula.new(backend.kind, backend.mixins, backend.attributes, backend.links)
          @backend.check(@model)
          OCCI::Log.debug('Opennebula backend initialized')
        when 'http://rocci.info/server/backend#ec2'
          require 'occi/backend/ec2'
          @model.register(OCCI::Backend::EC2.kind_definition)
          @backend.check(@model)
          OCCI::Log.debug('EC2 backend initialized')
        #@backend = OCCI::Backend::EC2.new(backend.kind,backend.mixins,backend.attributes,backend.links)
        else
          raise "Backend #{backend.kind} unknown"
      end

      super
    end

    def check_authorization
      #

      #
      #  # TODO: investigate usage fo expiration time and session cookies
      #  expiration_time = Time.now.to_i + 1800
      #
      #  token = @one_auth.login_token(expiration_time, username)
      #
      #  Client.new(token, @endpoint)

      basic_auth  = Rack::Auth::Basic::Request.new(env)
      digest_auth = Rack::Auth::Digest::Request.new(env)
      if basic_auth.provided? && basic_auth.basic?
        username, password = basic_auth.credentials
        halt 403, "Password in request does not match password of user #{username}" unless @backend.authorized?(username, password)
        puts "basic auth successful"
        username
      elsif digest_auth.provided? && digest_auth.digest?
        username, password = digest_auth.credentials
        halt 403, "Password in request does not match password of user #{username}" unless @backend.authorized?(username, password)
        username
      elsif request.env['SSL_CLIENT_S_DN']
        # For https, the web service should be set to include the user cert in the environment.

        cert_subject = request.env['SSL_CLIENT_S_DN']
        # Password should be DN with whitespace removed.
        username     = @backend.get_username(cert_subject)

        OCCI::Log.debug "Cert Subject: #{cert_subject}"
        OCCI::Log.debug "Username: #{username.inspect}"
        OCCI::Log.debug "Username nil?: #{username.nil?}"

        halt 403, "User with DN #{cert_subject} could not be authenticated" if username.nil?
        username
      else
        'anonymous'
      end
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

    # GET request

    # tasks to be executed before the request is handled
    before do

      OCCI::Log.debug('--------------------------------------------------------------------')
      OCCI::Log.debug("### Client IP: #{request.ip}")
      OCCI::Log.debug("### Client Accept: #{request.accept}")
      OCCI::Log.debug("### Client User Agent: #{request.user_agent}")
      OCCI::Log.debug("### Client Request URL: #{request.url}")
      OCCI::Log.debug("### Client Request method: #{request.request_method}")
      OCCI::Log.debug("### Client Request Media Type: #{request.media_type}")
      OCCI::Log.debug("### Client Request header: #{request.env.select { |k, v| k.include? 'HTTP' }}")
      OCCI::Log.debug("### Client SSL certificate subject: #{request.env['SSL_CLIENT_S_DN']}")
      OCCI::Log.debug("### Client Request body: #{request.body.read}")
      OCCI::Log.debug('--------------------------------------------------------------------')
      request.body.rewind

      OCCI::Log.debug('### Check authorization ###')
      user = check_authorization
      OCCI::Log.debug("### User #{user} authenticated successfully")
      @client = @backend.client(user)

      OCCI::Log.debug('### Prepare response ###')
      response['Accept'] = "application/occi+json,application/json,text/plain,text/uri-list,application/xml,text/xml,application/occi+xml"
      response['Server'] = "rOCCI/#{OCCI::Server::VERSION} OCCI/1.1"
      OCCI::Log.debug('### Initialize response OCCI collection ###')
      @collection = OCCI::Collection.new
      @locations  = Array.new
      OCCI::Log.debug('### Reset OCCI model ###')
      @backend.model.reset
      OCCI::Log.debug('### Parse request')
      @backend.model.get_by_location(request.path_info) ? entity_type = @backend.model.get_by_location(request.path_info).entity_type : entity_type = OCCI::Core::Resource
      @request_locations, @request_collection = OCCI::Parser.parse(request.media_type, request.body.read, request.path_info.include?('/-/'), entity_type, request.env)
      OCCI::Log.debug("Locations: #{@request_locations}")
      OCCI::Log.debug("Collection: #{@request_collection.to_json.to_s}")
      OCCI::Log.debug('### Fill OCCI model with entities from backend ###')
      @backend.register_existing_resources(@client)
      OCCI::Log.debug('### Finished response initialization starting with processing the request ...')
    end

    after do
      @collection ||= OCCI::Collection.new
      @locations  ||= Array.new
      OCCI::Log.debug('### Rendering response ###')
      OCCI::Log.debug("### Collection : \n #{@collection.to_json}")
      respond_to do |f|
        f.txt { erb :collection, :locals => { :collection => @collection, :locations => @locations } }
        f.on('*/*') { erb :collection, :locals => { :collection => @collection, :locations => @locations } }
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
      OCCI::Log.info("### Listing all kinds, mixins and actions ###")
      @collection = @backend.model.get(@request_collection)
      status 200
    end

# Resource retrieval
# returns entities either below a certain path or belonging to a certain kind or mixin
    get '*' do
      OCCI::Log.debug('GET')
      if request.path_info.end_with?('/')
        if request.path_info == '/'
          kinds = @backend.model.get.kinds
        else
          kinds = [@backend.model.get_by_location(request.path_info)]
        end

        kinds.each do |kind|
          OCCI::Log.info("### Listing all entities of kind #{kind.type_identifier} ###")
          @collection.resources.concat kind.entities if kind.entity_type == OCCI::Core::Resource
          @collection.links.concat kind.entities if kind.entity_type == OCCI::Core::Link
          @locations.concat kind.entities.collect { |entity| request.base_url + request.script_name + entity.location }
        end
      else
        kind = @backend.model.get_by_location(request.path_info.rpartition('/').first + '/')
        uuid = request.path_info.rpartition('/').last
        error 404 if kind.nil? or uuid.nil?
        OCCI::Log.info("### Listing entity with uuid #{uuid} ###")
        @collection.resources = kind.entities.select { |entity| entity.id == uuid } if kind.entity_type == OCCI::Core::Resource
        @collection.links = kind.entities.select { |entity| entity.id == uuid } if kind.entity_type == OCCI::Core::Link
      end
      status 200
    end

# ---------------------------------------------------------------------------------------------------------------------
# POST request
    post '/-/', '/.well-known/org/ogf/occi/-/' do
      logger.info("## Creating user defined mixin ###")
      raise "Mixin already exists!" if @backend.model.get(@request_collection).mixins.any?
      @request_collection.mixins.each do |mixin|
        @backend.model.register(mixin)
        # TODO: inform backend about new mixin
      end
    end

# Create an instance appropriate to category field and optionally link an instance to another one
    post '*' do
      OCCI::Log.debug('### POST request processing ...')
      category = @backend.model.get_by_location(request.path_info.rpartition('/').first + '/')

      if category.nil?
        OCCI::Log.debug("### No category found for request location #{request.path_info} ###")
        status 404
      end

      # if action
      if params[:action]
        OCCI::Log.debug("### Action #{params[:action]} triggered ...")
        action = nil
        if @request_collection.actions.any?
          action = @request_collection.actions.first
          params[:method] ||= action.attributes[:method] if action
        else
          OCCI::Log.debug("Category actions #{category.actions}")
          action = @backend.model.get_by_id(category.actions.select { |action| action.split('#').last == params[:action] }.first)
        end
        halt 400, "Corresponding category for action #{params[:action]} not found" if action.nil?
        OCCI::Log.debug(action)
        if request.path_info.end_with?('/')
          category.entities.each do |entity|
            OCCI::Backend::Manager.delegate_action(@client, @backend, action, params, entity)
            status 200
          end
        else
          entity = category.entities.select { |entity| entity.id == request.path_info.rpartition('/').last }.first
          OCCI::Backend::Manager.delegate_action(@client, @backend, action, params, entity)
          status 200
        end
      elsif category.kind_of?(OCCI::Core::Kind)
        @request_collection.resources.each do |resource|
          kind = @backend.model.get_by_id category.type_identifier
          # if resource with ID already exists then return 409 Conflict
          halt 409 if kind.entities.select {|entity| entity.id == resource.id}.any?
          OCCI::Log.debug("Deploying resource with title #{resource.title} in backend #{@backend.class.name}")
          OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DEPLOY, resource)
          @locations << request.base_url + request.script_name + resource.location
          status 201
        end
      elsif category.kind_of?(OCCI::Core::Mixin)
        @request_collection.locations.each do |location|
          OCCI::Log.debug("Attaching resource #{resource.title} to mixin #{mixin.type_identifier} in backend #{@backend.class.name}")
          # TODO: let backend carry out tasks related to the added mixin
          category.entities << OCCI::Rendering::HTTP::LocationRegistry.get_object(location)
          status 200
        end
      else
        status 400
      end

    end

# ---------------------------------------------------------------------------------------------------------------------
# PUT request

    put '*' do
      status 501
      break
      ## Add an resource instance to a mixin
      #unless @occi_request.mixins.empty?
      #  mixin = OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info)
      #
      #  @occi_request.locations.each do |location|
      #    entity = OCCI::Rendering::HTTP::LocationRegistry.get_object(URI.parse(location).path)
      #
      #    raise "No entity found at location: #{entity_location}" if entity == nil
      #    raise "Object referenced by uri [#{entity_location}] is not a OCCI::Core::Resource instance!" if !entity.kind_of?(OCCI::Core::Resource)
      #
      #    logger.debug("Associating entity [#{entity}] at location #{entity_location} with mixin #{mixin}")
      #
      #    entity.mixins << mixin
      #  end
      #  break
      #end
      #
      ## Update resource instance(s) at the given location
      #unless OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info).nil?
      #  entities = []
      #  # Determine set of resources to be updated
      #  if OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info).kind_of?(OCCI::Core::Resource)
      #    entities = [OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info)]
      #  elsif not OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info).kind_of?(OCCI::Core::Category)
      #    entities = OCCI::Rendering::HTTP::LocationRegistry.get_resources_below_location(request.path_info, @backend.model.get_all)
      #  elsif OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info).kind_of?(OCCI::Core::Category)
      #    object = OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info)
      #    @occi_request.locations.each do |loc|
      #      entities << OCCI::Rendering::HTTP::LocationRegistry.get_object(URI.parse(loc.chomp('"').reverse.chomp('"').reverse).path)
      #    end
      #  end
      #  logger.info("Full update for [#{entities.size}] entities...")
      #
      #  # full update of mixins
      #  object.entities.each do |entity|
      #    entity.mixins.delete(object)
      #    object.entities.delete(entity)
      #  end if object.kind_of?(OCCI::Core::Mixin)
      #
      #  entities.each do |entity|
      #    logger.debug("Adding entity: #{entity.get_location} to mixin #{object.type_identifier}")
      #    entity.mixins.push(object).uniq!
      #    object.entities.push(entity).uniq!
      #  end if object.kind_of?(OCCI::Core::Mixin)
      #
      #  # full update of attributes
      #  entities.each do |entity|
      #    # Refresh information from backend for entities of type resource
      #    # TODO: full update
      #    entity.attributes.merge!(@occi_request.attributes)
      #    # TODO: update entity in backend
      #  end unless @occi_request.attributes.empty?
      #
      #  # full update of links
      #  # TODO: full update e.g. delete old links first
      #  @occi_request.links.each do |link_data|
      #    logger.debug("Extracted link data: #{link_data}")
      #    raise "Mandatory information missing (related | target | category)!" unless link_data.related != nil && link_data.target != nil && link_data.category != nil
      #
      #    link_mixins = []
      #    link_kind = nil
      #    link_data.category.split(' ').each do |link_category|
      #      begin
      #        cat = @backend.model.get_by_id(link_category)
      #      rescue OCCI::CategoryNotFoundException => e
      #        logger.info("Category #{link_category} not found")
      #        next
      #      end
      #      link_kind = cat if cat.kind_of?(OCCI::Core::Kind)
      #      link_mixins << cat if cat.kind_of?(OCCI::Core::Mixin)
      #    end
      #
      #    raise "No kind for link category #{link_data.category} found" if link_kind.nil?
      #
      #    target_location = link_data.target_attr
      #    target = OCCI::Rendering::HTTP::LocationRegistry.get_object(target_location)
      #
      #    entities.each do |entity|
      #
      #      source_location = OCCI::Rendering::HTTP::LocationRegistry.get_location_of_object(entity)
      #
      #      link_attributes = link_data.attributes.clone
      #      link_attributes["occi.core.target"] = target_location.chomp('"').reverse.chomp('"').reverse
      #      link_attributes["occi.core.source"] = source_location
      #
      #      link = link_kind.entity_type.new(link_attributes, link_mixins)
      #      OCCI::Rendering::HTTP::LocationRegistry.register_location(link.get_location(), link)
      #
      #      target.links << link
      #      entity.links << link
      #    end
      #  end
      #  break
      #end
      #
      #response.status = OCCI::Rendering::HTTP::Response::HTTP_NOT_FOUND
      ## Create resource instance at the given location
      #raise "Creating resources with method 'put' is currently not possible!"
      #
      ## This must be the last statement in this block, so that sinatra does not try to respond with random body content
      ## (or fail utterly while trying to do that!)
      #nil

    end

# ---------------------------------------------------------------------------------------------------------------------
# DELETE request

    delete '/-/', '/.well-known/org/ogf/occi/-/' do
      # Location references query interface => delete provided mixin
      raise OCCI::CategoryMissingException if @request_collection.mixins.nil?
      mixins = @backend.model.get(@request_collection).mixins
      raise OCCI::MixinNotFoundException if mixins.nil?
      mixins.each do |mixin|
        OCCI::Log.debug("### Deleting mixin #{mixin.type_identifier} ###")
        mixin.entities.each do |entity|
          entity.mixins.delete(mixin)
        end
        # TODO: Notify backend to delete mixin and unassociate entities
        @backend.model.unregister(mixin)
      end
      status 200
    end

    delete '*' do

      # unassociate resources specified by URI in payload from mixin specified by request location
      if request.path_info == '/'
        categories = @backend.model.get.kinds
      else
        categories = [@backend.model.get_by_location(request.path_info.rpartition('/').first + '/')]
      end

      categories.each do |category|
        case category
          when OCCI::Core::Mixin
            mixin = category
            OCCI::Log.debug("### Deleting entities from mixin #{mixin.type_identifier} ###")
            @request_collection.locations.each do |location|
              uuid = location.to_s.rpartition('/').last
              mixin.entities.delete_if { |entity| entity.id == uuid }
            end
          when OCCI::Core::Kind
            kind = category
            if request.path_info.end_with?('/')
              if @request_collection.mixins.any?
                @request_collection.mixins.each do |mixin|
                  OCCI::Log.debug("### Deleting entities from kind #{kind.type_identifier} with mixin #{mixin.type_identifier} ###")
                  kind.entities.each { |entity| OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DELETE, entity) if mixin.include?(entity) }
                  kind.entities.delete_if { |entity| mixin.include?(entity) }
                  # TODO: links
                end
              else
                # TODO: links
                OCCI::Log.debug("### Deleting entities from kind #{kind.type_identifier} ###")
                kind.entities.each { |resource| OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DELETE, resource) }
                kind.entities.clear
              end
            else
              uuid = request.path_info.rpartition('/').last
              OCCI::Log.debug("### Deleting entity with id #{uuid} from kind #{kind.type_identifier} ###")
              kind.entities.each { |entity| OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DELETE, entity) if entity.id == uuid}
              kind.entities.delete_if { |entity| entity.id == uuid }
            end
        end
      end

      # delete entities


      #  # Location references a mixin => unassociate all provided resources (by X_OCCI_LOCATION) from it
      #  object = OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info)
      #  if object != nil && object.kind_of?(OCCI::Core::Mixin)
      #    mixin = OCCI::Rendering::HTTP::LocationRegistry.get_object(request.path_info)
      #    logger.info("Unassociating entities from mixin: #{mixin}")
      #
      #    @occi_request.locations.each do |loc|
      #      entity = OCCI::Rendering::HTTP::LocationRegistry.get_object(URI.parse(loc.chomp('"').reverse.chomp('"').reverse).path)
      #      mixin.entities.delete(entity)
      #      entity.mixins.delete(mixin)
      #    end
      #    break
      #  end
      #
      #  entities = OCCI::Rendering::HTTP::LocationRegistry.get_resources_below_location(request.path_info, @occi_request.categories)
      #
      #  unless entities.nil?
      #    entities.each do |entity|
      #      location = entity.get_location
      #      OCCI::Backend::Manager.signal_resource(@backend, OCCI::Backend::RESOURCE_DELETE, entity) if entity.kind_of? OCCI::Core::Resource
      #      # TODO: delete links in backend!
      #      entity.delete
      #      OCCI::Rendering::HTTP::LocationRegistry.unregister(location)
      #    end
      #    break
      #  end
      #
      #  response.status = OCCI::Rendering::HTTP::Response::HTTP_NOT_FOUND
      #  # This must be the last statement in this block, so that sinatra does not try to respond with random body content
      #  # (or fail utterly while trying to do that!)
      #  nil

    end

    error do
      OCCI::Log.error(sinatra.error)
      'Sorry there was a nasty error - ' + env['sinatra.error'].name
    end

  end
end
