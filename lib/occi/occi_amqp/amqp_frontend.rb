require "amqp"
require "occi/occi_amqp/amqp_consumer"
require "occi/occi_amqp/amqp_worker"
require "occi/occi_amqp/amqp_producer"
require "occi/occi_amqp/amqp_request"
require "occi/occi_amqp/amqp_response"
require "occi/config"
require "erb"

module OCCI
  module OCCI_AMQP
    class AmqpFrontend < OCCI::OCCI_AMQP::AmqpConsumer

      #
      # Initialize the AMQP Frontend
      #
      def initialize(server, identifier = Config.instance.amqp[:identifier])

        log("debug", __LINE__, "Initialize AMQPFrontend")

        @server     = server
        @identifier = identifier

        Thread.new { run }

        super()
      end

      def run
        log("debug", __LINE__, "Start AMQP Connection")

        begin

          AMQP.start(Config.instance.amqp[:connection_setting]) do |connection, open_ok|
            channel  = AMQP::Channel.new(connection)
            worker   = OCCI::OCCI_AMQP::AmqpWorker.new(channel, self, @identifier)
            worker.start

            @reply_producer = OCCI::OCCI_AMQP::AmqpProducer.new(channel, channel.default_exchange)

            log("debug", __LINE__, "AMQP Connection ready")
          end

        rescue Exception => e
          log("error", __LINE__, "Amqp Thread get an Error: #{e.message} \n #{e.backtrace.join("\n")}")
        end
      end

      def handle_message(metadata, payload)
        log("debug", __LINE__, "Handle message: #{ payload }")

        begin

          @amqp_request  = OCCI::OCCI_AMQP::AmqpRequest.new(payload, metadata)
          @amqp_response = OCCI::OCCI_AMQP::AmqpResponse.new(@amqp_request, metadata)

          before_executing
          do_executing
          after_executing

        rescue Exception => e
          # TODO send raised exeption to reply queue
          log("error", __LINE__, "Received a message get an Error: #{e.message} \n #{e.backtrace.join("\n")}")
        end
      end

      private
      ##################################################################################################################

      def before_executing
        user = 'anonymous' #check_authorization
        @backend = @server.backend
        @client  = @backend.client(user)

        @collection = OCCI::Collection.new
        @locations  = Array.new

        @backend.model.reset
        @backend.model.get_by_location(@amqp_request.path_info) ? entity_type = @backend.model.get_by_location(@amqp_request.path_info).entity_type : entity_type = OCCI::Core::Resource
        @request_locations, @request_collection = OCCI::Parser.parse(@amqp_request.content_type, @amqp_request.payload, @amqp_request.is_category, entity_type, @amqp_request.header)
        @backend.register_existing_resources(@client)
      end

      def do_executing
        begin
          method = method(@amqp_request.type)
          method.call(@amqp_request)
        rescue Exception => e
          message = "Executing a message get an Error: #{e.message}"
          log("error", __LINE__, "#{ message } \n #{e.backtrace.join("\n")}")
          @amqp_response.error 500, "rOCCI_Server: #{ message }"
        end
      end

      def after_executing
        @amqp_response.collection = @collection
        @amqp_response.locations  = @locations

        @reply_producer.send(@amqp_response.generate_output, @amqp_response.reply_options)
      end

      def get(request)
        log("debug", __LINE__, "Handle get: #{ request }")

        if request.path_info == "/-/"
          # discovery interface
          log("debug", __LINE__, "Handle get discovery interface")

          @collection = @backend.model.get(@request_collection)
        else
          # resource request
          log("debug", __LINE__, "Handle get resource request")

          if request.path_info.end_with?('/')
            if request.path_info == '/'
              kinds = @backend.model.get.kinds
            else
              kinds = [@backend.model.get_by_location(request.path_info)]
            end

            kinds.each do |kind|
              log("info", __LINE__, "### Listing all entities of kind #{kind.type_identifier} ###")

              @collection.resources.concat kind.entities if kind.entity_type == OCCI::Core::Resource
              @collection.links    .concat kind.entities if kind.entity_type == OCCI::Core::Link
              @locations           .concat kind.entities.collect { |entity| request.base_url + request.script_name + entity.location }
            end
          else
            kind = @backend.model.get_by_location(request.path_info.rpartition('/').first + '/')
            uuid = request.path_info.rpartition('/').last

            if kind == nil or uuid == nil
              log("error", __LINE__, "kind is nil")

              @amqp_response.status_code = 404

              return
            end

            log("info", __LINE__, "### Listing entity with uuid #{uuid} ###")

            @collection.resources = kind.entities.select { |entity| entity.id == uuid } if kind.entity_type == OCCI::Core::Resource
            @collection.links     = kind.entities.select { |entity| entity.id == uuid } if kind.entity_type == OCCI::Core::Link
          end
        end

        @amqp_response.status_code = 200

      end

      def post(request)
        log("debug", __LINE__, "Handle post: #{ request }")

        params = @amqp_request.params

        if request.path_info == "/-/" or request.path_info == "/.well-known/org/ogf/occi/-/"
          # create mixin to interface
          # TODO untested
          log("debug", __LINE__, "Handle get create mixin to interface")

          raise "Mixin already exists!" if @backend.model.get(@request_collection).mixins.any?

          @request_collection.mixins.each do |mixin|
            @backend.model.register(mixin)
            # TODO: inform backend about new mixin
          end
        else
          # create an instance appropriate to category field and optionally link an instance to another one
          log("debug", __LINE__, "Handle post create an instance or link an instance to another one")

          category = @backend.model.get_by_location(request.path_info.rpartition('/').first + '/')

          if category.nil?
            log("debug", __LINE__, "### No category found for request location #{request.path_info} ###")
            @amqp_response.status_code = 404
          end

          # if action
          if params[:action]
            # TODO implement amqp post action
            log("debug", __LINE__, "### Action #{ @amqp_request.params } triggered ...")

            action = nil
            if @request_collection.actions.any?
              action = @request_collection.actions.first
              params[:method] ||= action.attributes[:method] if action
            else
              log("debug", __LINE__, "Category actions #{category.actions}")
              action = @backend.model.get_by_id(category.actions.select { |action| action.split('#').last == params[:action] }.first)
            end
            @amqp_response.error 400, "Corresponding category for action #{params[:action]} not found" if action.nil?
            log("debug", __LINE__, action)

            if request.path_info.end_with?('/')
              category.entities.each do |entity|
                OCCI::Backend::Manager.delegate_action(@client, @backend, action, params, entity)
                @amqp_response.status_code = 200
              end
            else
              entity = category.entities.select { |entity| entity.id == request.path_info.rpartition('/').last }.first
              OCCI::Backend::Manager.delegate_action(@client, @backend, action, params, entity)
              @amqp_response.status_code = 200
            end

          elsif category.kind_of?(OCCI::Core::Kind)
            log("debug", __LINE__, "### Create Kind triggered ...")

            @request_collection.resources.each do |resource|
              kind = @backend.model.get_by_id category.type_identifier
              # if resource with ID already exists then return 409 Conflict

              if kind.entities.select {|entity| entity.id == resource.id}.any?
                @amqp_response.status_code = 409
                return
              end

              log("debug", __LINE__, "Deploying resource with title #{resource.title} in backend #{@backend.class.name}")

              OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DEPLOY, resource)

              # TODO where can i get the base_url and the script_name (i am in an amqp environment)
              @locations << request.base_url + request.script_name + resource.location
              @amqp_response.status_code =  201
            end
          elsif category.kind_of?(OCCI::Core::Mixin)
            # TODO implement amqp post mixin
            log("debug", __LINE__, "### Create Mixin triggered ...")
          else
            @amqp_response.status_code = 400
          end
        end
      end

      def pull(request)
        # TODO implement amqp pull
        log("debug", __LINE__, "Handle pull: #{ request }")
      end

      def delete(request)
        # TODO implement amqp delete
        log("debug", __LINE__, "Handle delete: #{ request }")

        if request.path_info == "/-/" or request.path_info == "/.well-known/org/ogf/occi/-/"
          log("debug", __LINE__, "Handle delete provided mixin")

          raise OCCI::CategoryMissingException if @request_collection.mixins.nil?
          mixins = @backend.model.get(@request_collection).mixins
          raise OCCI::MixinNotFoundException if mixins.nil?

          mixins.each do |mixin|
            log("debug", __LINE__, "### Deleting mixin #{mixin.type_identifier} ###")

            mixin.entities.each do |entity|
              entity.mixins.delete(mixin)
            end

            # TODO: Notify backend to delete mixin and unassociate entities
            @backend.model.unregister(mixin)
          end

          @amqp_response.status_code = 200
        else
          log("debug", __LINE__, "Handle delete unassociate resources")

          if request.path_info == '/'
            categories = @backend.model.get.kinds
          else
            categories = [@backend.model.get_by_location(request.path_info.rpartition('/').first + '/')]
          end

          categories.each do |category|
            case category
              when OCCI::Core::Mixin
                mixin = category
                log("debug", __LINE__, "### Deleting entities from mixin #{mixin.type_identifier} ###")
                @request_collection.locations.each do |location|
                  uuid = location.to_s.rpartition('/').last
                  mixin.entities.delete_if { |entity| entity.id == uuid }
                end
              when OCCI::Core::Kind
                kind = category
                if request.path_info.end_with?('/')
                  if @request_collection.mixins.any?
                    @request_collection.mixins.each do |mixin|
                      log("debug", __LINE__, "### Deleting entities from kind #{kind.type_identifier} with mixin #{mixin.type_identifier} ###")
                      kind.entities.each { |entity| OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DELETE, entity) if mixin.include?(entity) }
                      kind.entities.delete_if { |entity| mixin.include?(entity) }
                      # TODO: links
                    end
                  else
                    # TODO: links
                    log("debug", __LINE__, "### Deleting entities from kind #{kind.type_identifier} ###")
                    kind.entities.each { |resource| OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DELETE, resource) }
                    kind.entities.clear
                  end
                else
                  uuid = request.path_info.rpartition('/').last
                  log("debug", __LINE__, "### Deleting entity with id #{uuid} from kind #{kind.type_identifier} ###")
                  kind.entities.each { |entity| OCCI::Backend::Manager.signal_resource(@client, @backend, OCCI::Backend::RESOURCE_DELETE, entity) if entity.id == uuid}
                  kind.entities.delete_if { |entity| entity.id == uuid }
                end
            end
            @amqp_response.status_code = 200
          end
        end
      end
    end
  end
end