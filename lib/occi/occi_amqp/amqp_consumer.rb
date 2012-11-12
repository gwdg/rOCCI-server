require "amqp"

module OCCI
  module OCCI_AMQP
    class AmqpConsumer

      def handle_message(metadata, payload)
        log("info", __LINE__, "Received a message: #{payload}, content_type = #{metadata.content_type}")
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