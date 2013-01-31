module Occi
  module Server
    module Frontend
      attr_accessor :backends

      def self.[](frontend)
        self.new(:frontend => frontend)
      end

      def self.new(attributes)
        attributes = attributes.dup # prevent delete from having side effects
        frontend = attributes.delete(:frontend).to_s.downcase.to_sym

        case frontend
          when :http
            require 'occi/server/frontend/http'
            Occi::Server::Frontend::Http.new(attributes)
          when :amqp
            require 'occi/server/frontend/amqp'
            Occi::Server::Frontend::Amqp.new(attributes)
          else
            raise Occi::Helper::FrontendError.new("#{frontend} is not a recognized as valid frontend")
        end
      end
    end
  end
end

