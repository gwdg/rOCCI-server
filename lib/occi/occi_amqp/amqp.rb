require 'amqp'

module OCCI
  module OCCI_AMQP
    class Amqp

      CONNECTION_SETTING = {
          :host => '10.108.16.15', #'134.76.4.90',
          :port => 5672,
          :password => 'stack',
      }
      # options => :routing_key, :message_exclusive
      def initialize (callback_handle_message, options = {})
        OCCI::Log.debug("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) OCCI/AMQP: Initializing occi_amqp")
        @amqp_options = options
        @amqp_options[:message_exclusive] = true
        @amqp_options[:auto_delete]       = true

        @callback_handle_message = callback_handle_message

        Thread.new { run }

      end

      def run
        OCCI::Log.debug("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) OCCI/AMQP: Initializing listening")

        AMQP.start(CONNECTION_SETTING) do |connection, open_ok|
          OCCI::Log.debug("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) OCCI/AMQP: Initializing channel")
          channel  = AMQP::Channel.new(connection)
          channel.on_error(&method(:handle_channel_exception))

          channel  = AMQP::Channel.new(connection)
          channel.on_error(&method(:handle_channel_exception))

          @exchange = channel.default_exchange

          OCCI::Log.debug("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) OCCI/AMQP: Initializing queue [ #{@amqp_options[:routing_key]}} ]")

          queue = channel.queue(
              @amqp_options[:routing_key],
              :exclusive   => @amqp_options[:message_exclusive],
              :auto_delete => @amqp_options[:auto_delete]
          )
          queue.subscribe(&method(:handle_message))
        end
      end

      def handle_channel_exception (channel, channel_close)
        message = "Channel-level exception [ code = #{channel_close.reply_code}, message = #{channel_close.reply_text} ]"
        OCCI::Log.error("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) OCCI/AMQP: #{message}")
      end

      def handle_message(metadata, payload)
        @callback_handle_message.call(metadata, payload)
      end

      def send(message, options = {})
        OCCI::Log.error("Script: (#{ File.basename(__FILE__)}) Line: (#{__LINE__}) OCCI/AMQP: Publish message [ #{options[:routing_key]}]")
        @exchange.publish(message, options)
      end
    end
  end
end

