require "occi/frontend/base/base_request"

module OCCI
  module Frontend
    module Http
      class HttpRequest < OCCI::Frontend::Base::BaseRequest
        attr_accessor :params
        #describe initialize amqp request
        #@param [String] payload content of the message
        #@param [AMQP::Metadata] information about the message
        def initialize(request)
          @request = request
        end

        #describe grep header from metadata
        def env
          @request.env
        end

        def body
          @request.body.read
        end

        def body_rewind
          @request.body.rewind
        end

        def path_info
          @request.path_info
        end

        def media_type
          @request.media_type
        end

        def base_url
          @request.base_url
        end

        def script_name
          @request.script_name
        end

        def accept
          @request.accept
        end
      end
    end
  end
end