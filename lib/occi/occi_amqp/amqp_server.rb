require "occi/occi_amqp/amqp"
require "occi/occi_amqp/amqp_request"
require "occi/occi_amqp/amqp_response"

module OCCI
  module OCCI_AMQP
    class AmqpServer
      def initialize (server)
        OCCI::Log.debug("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) OCCI/AMQP: Initializing AMQP Server")

        @server = server

        @occi_amqp = OCCI::OCCI_AMQP::Amqp.new(method(:handle_occi_message),:routing_key => "amqp.occi.cloud.gwdg.de.3300")
      end

      def handle_occi_message(metadata, payload)
        begin
          @amqp_request = OCCI::OCCI_AMQP::AmqpRequest.new
          @amqp_request.parse(payload, metadata)

          @amqp_response = OCCI::OCCI_AMQP::AmqpResponse.new
          @amqp_response.routing_key = metadata.reply_to

          before_executing
          do_executing
          after_executing

        rescue Exception => e
          OCCI::Log.error("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) Received a message get an Error: #{e.message}")
        end
      end

################### private stuff ######################################################################################
      private

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
        case @amqp_request.type
          when 'get'
            if @amqp_request.path_info == "/-/"
              get_discovery
            else
              get_entities
            end
          when 'put'
          when 'post'
          when 'delete'
        end
      end

      def after_executing
        @collection ||= OCCI::Collection.new
        @locations  ||= Array.new

        headers = {:status_code => @amqp_response.status_code}

        @occi_amqp.send(
            @collection.to_json,
            :routing_key  => @amqp_response.routing_key,
            :content_type => @amqp_request.accept,
            :correlation_id => @amqp_request.message_id,
            :headers      => headers
        )
      end

      def get_discovery
        OCCI::Log.debug("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) GET DISCOVERY")
        @collection = @backend.model.get(@request_collection)
      end

      def get_entities
        OCCI::Log.debug("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__})  GET ENTITIES")

        if @amqp_request.path_info.end_with?('/')
          if @amqp_request.path_info == '/'
            kinds = @backend.model.get.kinds
          else
            kinds = [@backend.model.get_by_location(@amqp_request.path_info)]
          end

          kinds.each do |kind|
            OCCI::Log.info("### Listing all entities of kind #{kind.type_identifier} ###")
            @collection.resources.concat kind.entities if kind.entity_type == OCCI::Core::Resource
            @collection.links.concat kind.entities if kind.entity_type == OCCI::Core::Link
            # @locations.concat kind.entities.collect { |entity| request.base_url + request.script_name + entity.location }
          end
        else
          kind = @backend.model.get_by_location(request.path_info.rpartition('/').first + '/')
          uuid = request.path_info.rpartition('/').last
          error 404 if kind.nil? or uuid.nil?
          OCCI::Log.info("### Listing entity with uuid #{uuid} ###")
          @collection.resources = kind.entities.select { |entity| entity.id == uuid } if kind.entity_type == OCCI::Core::Resource
          @collection.links = kind.entities.select { |entity| entity.id == uuid } if kind.entity_type == OCCI::Core::Link
        end
        @status_code = 200
      end
    end
  end
end