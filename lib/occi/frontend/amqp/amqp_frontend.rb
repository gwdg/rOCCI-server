require "occi/frontend/amqp/amqp_frontend"
require "occi/frontend/amqp/amqp_request"
require "occi/frontend/amqp/amqp_response"
require "occi/frontend/base/base_frontend"

module OCCI
  module Frontend
    module Amqp
      class AmqpFrontend < OCCI::Frontend::Base::BaseFrontend

        def initialize()
          log("debug", __LINE__, "Initialize AMQPFrontend")
          super
        end

        def check_authorization(request)
          'anonymous'
        end
      end
    end
  end
end