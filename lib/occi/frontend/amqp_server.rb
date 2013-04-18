require "amqp"
require "occi/occi_amqp/worker"
require "occi/config"
require "occi/frontend/amqp/amqp_frontend"

module OCCI
  module Frontend
    class AmqpServer

      attr_reader :response, :request

      #describe Initialize the AMQP Frontend
      # @param [Boolean] standalone should the amqp frontend start in an thread or as standalone process
      # @param [Object] identifier
      def initialize(standalone, identifier = Config.instance.amqp[:identifier], mock = false)

        log("debug", __LINE__, "Initialize AMQPFrontend")

        @identifier = identifier

        @frontend   = OCCI::Frontend::Amqp::AmqpFrontend.new()

        startAMQP standalone, identifier if !mock
      end

      def startAMQP(standalone = false, identifier)
        @worker =  OCCI::OCCI_AMQP::Worker.new
        @worker.start :queue_name => identifier, :callback => method(:handle_message)
        log("debug", __LINE__, "AMQP Connection ready")

        @frontend.backend.amqp_worker = @worker if @frontend.backend.respond_to? :amqp_worker

        @worker.join if standalone
      end

      # @param [Integer] code
      # @param [String] message
      def status (code, message = '')
        @response.status = code
      end

      # @param [Integer] code
      # @param [String] message
      def error (code, message = '')
        @response.error code, message
      end

      # @param [Integer] code
      # @param [String] message
      def halt (code, message = '')
        @response.status = code
      end

      # @describe binded methode to handle amqp message requests
      # @param [Hash] metadata
      # @param [String] payload
      def handle_message(metadata, payload)
        log("debug", __LINE__, "Handle message: #{ payload }")
        begin
          parse_message(metadata, payload)
          @worker.request(@response.generate_output, @response.reply_options)
        rescue Exception => e
          log("error", __LINE__, "Received a message get an Error: #{e.message} \n #{e.backtrace.join("\n")}")
        end
      end

      # @describe parse message and execute them
      # @param [Hash] metadata
      # @param [String] payload
      def parse_message(metadata, payload)
        @request  = OCCI::Frontend::Amqp::AmqpRequest.new(metadata, payload)
        @response = OCCI::Frontend::Amqp::AmqpResponse.new(@request, metadata)

        @frontend.server = self
        @frontend.before_execute @request
        @frontend.dynamic_execute @request.type, @request
        collection, locations = @frontend.after_execute @request

        @response.collection = collection
        @response.locations  = locations
      end

      def log(type, line, message)

        script_name =  File.basename(__FILE__);

        case type
          when "error"
            OCCI::Log.error("Script: (#{ script_name }) Line: (#{ line }) OCCI/AMQP: #{ message }")
          when "debug"
            OCCI::Log.debug("Script: (#{ script_name }) Line: (#{ line }) OCCI/AMQP: #{ message }")
          else
            OCCI::Log.info ("Script: (#{ script_name }) Line: (#{ line }) OCCI/AMQP: #{ message }")
        end
      end
    end
  end
end