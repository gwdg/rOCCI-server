require "amqp"
require "amqp/utilities/event_loop_helper"


module OCCI
  module OCCI_AMQP
    class Worker
      def initialize
        AMQP::Utilities::EventLoopHelper.run
      end

      def start(options = {})
        connection = AMQP.connect Config.instance.amqp[:connection_setting]

        channel = AMQP::Channel.new(connection)
        channel.on_error(&method(:handle_channel_exception))

        @queue = channel.queue(options[:queue_name], :exclusive => true, :auto_delete => true)
        @queue.subscribe(&options[:callback])

        @exchange = channel.default_exchange
      end

      def request(message, options = {})
        raise 'No exchange defined for this amqp worker' if @exchange.nil?

        log("debug", __LINE__, "Send AMQP Message: #{ message }")

        @exchange.publish(message, options)
      end

      def join
        t = AMQP::Utilities::EventLoopHelper.eventmachine_thread
        t.join unless t.nil?
      end

      def handle_channel_exception(channel, channel_close)
        log("error", __LINE__, "Channel-level exception [ code = #{channel_close.reply_code}, message = #{channel_close.reply_text} ]")
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
