require "amqp"


module OCCI
  module OCCI_AMQP
    class AmqpWorker

      def initialize(channel, consumer, queue_name = AMQ::Protocol::EMPTY_STRING)
        log("debug", __LINE__, "Initialize AMQP Worker with queue: #{ queue_name }")

        @queue_name = queue_name

        @channel    = channel
        @channel.on_error(&method(:handle_channel_exception))

        @consumer   = consumer
      end

      def start
        log("debug", __LINE__, "Start AMQP Worker with queue: #{ @queue_name }")

        @queue = @channel.queue(@queue_name, :exclusive => true, :auto_delete => true)
        @queue.subscribe(&@consumer.method(:handle_message))
      end

      def handle_channel_exception(channel, channel_close)
        log("error", __LINE__, "Channel-level exception [ code = #{channel_close.reply_code}, message = #{channel_close.reply_text} ]")
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