module OCCI
  module OCCI_AMQP
    class AmqpResponse
      attr_accessor :status_code, :payload, :routing_key

      def initialize
        status_code = "404"
      end
    end
  end
end
