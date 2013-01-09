require 'hashie/mash'

require 'occi'
require 'occi/exceptions'

module OCCI
  module Frontend
    module Base
      class BaseFrontend

        VERSION = "0.5.0"

        attr_accessor :server

        ACTIVE_BACKENDS = {
            'dummy'      => {:backend => 'Dummy'     , :register => true, :instance => true},
            'fogio'      => {:backend => 'Fogio'     , :register => true, :instance => true},
            'opennebula' => {:backend => 'OpenNebula', :register => true, :instance => true},
            'ec2'        => {:backend => 'EC2'       , :register => true, :instance => false},
        }

        def initialize()
          @model  = OCCI::Model.new

          collection   = Hashie::Mash.new(JSON.parse(File.read(File.dirname(__FILE__) + "/../../../../etc/backend/default.json")))
          backend      = collection.resources.first
          backend_name = backend.kind[(backend.kind.index("#") + 1) .. -1]

          unless ACTIVE_BACKENDS.has_key?(backend_name)
            raise "Backend #{backend.kind} unknown"
          end

          require 'occi/backend/' + backend_name.downcase
          backend_clazz = ACTIVE_BACKENDS[backend_name][:backend]

          if ACTIVE_BACKENDS[backend_name][:register]
            @model.register(OCCI::Backend.const_get(backend_clazz).kind_definition)
          end

          if ACTIVE_BACKENDS[backend_name][:instance]
            @backend = OCCI::Backend.const_get(backend_clazz).new(
                backend.kind,
                backend.mixins,
                backend.attributes,
                backend.links
            )
          end
        end

        # @describe must implement be your own frontend (http, amqp)
        # @param [OCCI::Frontend::Base::BaseRequest] request
        def check_authorization(request)
          raise "check_authorization is not implemented"
        end

        # @describe tasks to be executed before the request is handled
        # @param [OCCI::Frontend::Base::BaseRequest] request
        def before_execute(request)
          OCCI::Log.debug('### Check authorization ###')
          user = check_authorization(request)

          OCCI::Log.debug("### User #{user} authenticated successfully")
          @client = @backend.client(user)

          OCCI::Log.debug('### Prepare response ###')

          OCCI::Log.debug('### Initialize response OCCI collection ###')
          @collection = OCCI::Collection.new
          @locations  = Array.new

          OCCI::Log.debug('### Reset OCCI model ###')
          @backend.model.reset

          OCCI::Log.debug('### Parse request')
          @backend.model.get_by_location(request.path_info) ? entity_type = @backend.model.get_by_location(request.path_info).entity_type : entity_type = OCCI::Core::Resource
          @request_locations, @request_collection = OCCI::Parser.parse(request.media_type, request.body, request.path_info.include?('/-/'), entity_type, request.env)

          OCCI::Log.debug("Locations: #{@request_locations}")
          OCCI::Log.debug("Collection: #{@request_collection.to_json.to_s}")
          OCCI::Log.debug('### Fill OCCI model with entities from backend ###')
          @backend.register_existing_resources(@client)

          OCCI::Log.debug('### Finished response initialization starting with processing the request ...')
        end

        # @describe delegate request to the resource request
        # @param [String] type
        # @param [OCCI::Frontend::Base::BaseRequest] request
        def dynamic_execute(type, request)
          begin
            method(type).call(request)
          rescue Exception => e
            message = "Executing a message get an Error: #{e.message}"
            log("error", __LINE__, "#{ message } \n #{e.backtrace.join("\n")}")
            @server.error 500, "rOCCI_Server: #{ message }"
          end
        end

        # @param [OCCI::Frontend::Base::BaseRequest] request
        def after_execute(request)
          @collection ||= OCCI::Collection.new
          @locations  ||= Array.new

          OCCI::Log.debug('### Rendering response ###')
          OCCI::Log.debug("### Collection : \n #{@collection.to_json}")

          return @collection, @locations
        end

        private
        ##################################################################################################################

        # ---------------------------------------------------------------------------------------------------------------------
        # Get request

        # @describe discovery interface and Resource retrieval - returns all kinds, mixins and actions registered for the server or returns entities either below a certain path or belonging to a certain kind or mixin
        # @param [OCCI::Frontend::Base::BaseRequest] request
        def get(request)
          if request.path_info == "/-/" or request.path_info == "/.well-known/org/ogf/occi/-/"
            OCCI::Log.info("### Listing all kinds, mixins and actions ###")
            @collection = @backend.model.get(@request_collection)
            @server.status 200
          else
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

              if kind == nil or uuid == nil
                log("error", __LINE__, "kind is nil")
                @server.status 404
                return
              end

              OCCI::Log.info("### Listing entity with uuid #{uuid} ###")
              @collection.resources = kind.entities.select { |entity| entity.id == uuid } if kind.entity_type == OCCI::Core::Resource
              @collection.links = kind.entities.select { |entity| entity.id == uuid } if kind.entity_type == OCCI::Core::Link
            end
            @server.status 200
          end
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # POST request

        # @describe Create an instance appropriate to category field and optionally link an instance to another one
        # @param [OCCI::Frontend::Base::BaseRequest] request
        def post(request)
          params = request.params

          if request.path_info == "/-/" or request.path_info == "/.well-known/org/ogf/occi/-/"
            logger.info("## Creating user defined mixin ###")
            raise "Mixin already exists!" if @backend.model.get(@request_collection).mixins.any?
            @request_collection.mixins.each do |mixin|
              @backend.model.register(mixin)
              # TODO: inform backend about new mixin
            end
          else
            OCCI::Log.debug('### POST request processing ...')
            category = @backend.model.get_by_location(request.path_info.rpartition('/').first + '/')

            if category.nil?
              OCCI::Log.debug("### No category found for request location #{request.path_info} ###")
              @server.status 404
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

              @server.error 400, "Corresponding category for action #{params[:action]} not found" if action.nil?

              OCCI::Log.debug(action)
              if request.path_info.end_with?('/')
                category.entities.each do |entity|
                  OCCI::Backend::Manager.delegate_action(@client, @backend, action, params, entity)
                  @server.status 200
                end
              else
                entity = category.entities.select { |entity| entity.id == request.path_info.rpartition('/').last }.first
                OCCI::Backend::Manager.delegate_action(@client, @backend, action, params, entity)
                @server.status 200
              end
            elsif category.kind_of?(OCCI::Core::Kind)
              @server.status 400

              @request_collection.resources << OCCI::Core::Resource.new(category.type_identifier) if @request_collection.resources.empty?

              @request_collection.resources.each do |resource|
                kind = @backend.model.get_by_id category.type_identifier

                # if resource with ID already exists then return 409 Conflict
                if kind.entities.select {|entity| entity.id == resource.id}.any?
                  @server.status 409
                  return
                end

                # check resource attributes against their definition and set default attributes
                resource.check @backend.model

                OCCI::Log.debug("Deploying resource with title #{resource.title} in backend #{@backend.class.name}")
                OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DEPLOY, resource)

                @locations << request.base_url + request.script_name + resource.location
                @server.status 201
              end
            elsif category.kind_of?(OCCI::Core::Mixin)
              @request_collection.locations.each do |location|
                OCCI::Log.debug("Attaching resource #{resource.title} to mixin #{mixin.type_identifier} in backend #{@backend.class.name}")
                # TODO: let backend carry out tasks related to the added mixin
                category.entities << OCCI::Rendering::HTTP::LocationRegistry.get_object(location)
                @server.status 200
              end
            else
              @server.status 400
            end
          end
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # PUT request

        # @param [OCCI::Frontend::Base::BaseRequest] request
        def put(request)
          # TODO implement pull
          log("debug", __LINE__, "Handle pull: #{ request }")
          @server.status 501
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # DELETE request

        # @param [OCCI::Frontend::Base::BaseRequest] request
        def delete(request)
          if request.path_info == "/-/" or request.path_info == "/.well-known/org/ogf/occi/-/"
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
            @server.status 200
          else
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
          end
        end

        # @param [String] type
        # @param [Integer] line
        # @param [String] message
        def log(type, line, message)

          script_name =  File.basename(__FILE__);

          case type
            when "error"
              OCCI::Log.error("Script: (#{ script_name }) Line: (#{ line }) OCCI: #{ message }")
            when "debug"
              OCCI::Log.debug("Script: (#{ script_name }) Line: (#{ line }) OCCI: #{ message }")
            else
              OCCI::Log.info ("Script: (#{ script_name }) Line: (#{ line }) OCCI: #{ message }")
          end
        end
      end
    end
  end
end
