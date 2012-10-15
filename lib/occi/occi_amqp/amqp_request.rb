module OCCI
  module OCCI_AMQP
    class AmqpRequest
      attr_reader :payload, :path_info, :accept, :type, :content_type, :message_id, :is_category, :header

      def parse(payload, metadata)
        @payload      = payload
        @path_info    = metadata.headers["location"]
        @accept       = metadata.headers["accept"]
        @type         = metadata.type
        @content_type = metadata.content_type
        @message_id   = metadata.message_id
        @header       = metadata.headers
        @is_category  = true;
      end

    end
  end
end