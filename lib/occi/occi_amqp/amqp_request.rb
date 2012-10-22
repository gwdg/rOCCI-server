require "CGI"
module OCCI
  module OCCI_AMQP
    class AmqpRequest
      attr_reader :payload, :path_info, :accept, :type, :content_type, :message_id, :is_category, :base_url, :script_name, :params

      def initialize(payload, metadata)
        parse(payload, metadata)
      end

      def header
        return {
            'HTTP_X_OCCI_ATTRIBUTE' => @header["X_OCCI_ATTRIBUTE"],
            'HTTP_X_OCCI_LOCATION'  => @header["X_OCCI_LOCATION"],
            'HTTP_CATEGORY'         => @header["CATEGORY"],
            'HTTP_LINK'             => @header["LINK"],
        }
      end

      private
      ##################################################################################################################

      def parse(payload, metadata)
        @payload          = payload
        @params           = parse_params(metadata.headers["path_info"].split("?"))
        @path_info        = metadata.headers["path_info"].split("?")[0]
        @accept           = metadata.headers["accept"]
        @type             = metadata.type
        @content_type     = metadata.content_type || "occi/text"
        @message_id       = metadata.message_id

        @header = metadata.headers.inject({}) do |hash, keys|
          hash[keys[0].upcase] = keys[1]
          hash
        end

        @base_url         = "base_url_dummy"
        @script_name      = "script_name_dummy"
        @is_category      = @path_info.include?('/-/');
      end

      def parse_params(query)
        params = Hash.new

        if query != nil && query.size > 1
          params = CGI::parse(query[1]).inject({}) do |hash, keys|
            if keys[1].size < 2
              hash[keys[0].to_sym] = keys[1].first
            else
              hash[keys[0].to_sym] = keys[1]
            end
            hash
          end
        end

        return params
      end
    end
  end
end