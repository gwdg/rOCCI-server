require "amqp"

module OCCI
  module OCCI_AMQP
    class AmqpProducer

      def initialize(channel, exchange)
        log("debug", __LINE__, "Intialize AMQP Producer")

        @channel  = channel
        @exchange = exchange
      end

      def send(message, options = {})
        log("debug", __LINE__, "Send AMQP Message: #{ message }")

        @exchange.publish(message, options)
      end

      private
      ##################################################################################################################

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