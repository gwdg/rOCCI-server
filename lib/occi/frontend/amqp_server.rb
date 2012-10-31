require "amqp"
require "occi/occi_amqp/amqp_consumer"
require "occi/occi_amqp/amqp_worker"
require "occi/occi_amqp/amqp_producer"
require "occi/config"
require "occi/frontend/amqp/amqp_frontend"

module OCCI
  module Frontend
    class AmqpServer < OCCI::OCCI_AMQP::AmqpConsumer

      attr_reader :response, :request

      #describe Initialize the AMQP Frontend
      def initialize(standalone, identifier = Config.instance.amqp[:identifier])

        log("debug", __LINE__, "Initialize AMQPFrontend")

        @identifier = identifier
        @frontend   = OCCI::Frontend::Amqp::AmqpFrontend.new()

        start standalone

        super()
      end

      #describe Start the amqp frontend
      #@param [boolean] standalone should the amqp frontend start in an thread or as standalone process
      def start(standalone = false)
        if standalone
          run
        else
          Thread.new { run }
        end
      end

      #describe Eventloop for amqp connection
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

      def status (code, message = '')
        @response.status = code
      end

      def error (code, message = '')
        @response.error code, message
      end

      def halt (code, message = '')
        @response.status = code
      end

      #describe binded methode to handle amqp message requests
      #@param metadata
      #@param payload
      def handle_message(metadata, payload)
        log("debug", __LINE__, "Handle message: #{ payload }")
        begin
          parse_message(metadata, payload)
          @reply_producer.send(@response.generate_output, @response.reply_options)
        rescue Exception => e
          log("error", __LINE__, "Received a message get an Error: #{e.message} \n #{e.backtrace.join("\n")}")
        end
      end

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
    end
  end
end