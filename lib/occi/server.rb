require 'occi'
require 'occi/server/helper/exceptions'
require "occi/server/helper/config"
require "occi/server/frontend"
require "occi/server/backend"

Encoding.default_external = Encoding::UTF_8 if defined? Encoding
Encoding.default_internal = Encoding::UTF_8 if defined? Encoding

module Occi
  class Server
    VERSION = "0.9.0"

    def self.start(frontend_identifier = 'http')
      logger = Logger.new(STDERR)

      @log_subscriber = ActiveSupport::Notifications.subscribe("log") do |name, start, finish, id, payload|
        logger.log(payload[:level], payload[:message])
      end

      frontend          = Occi::Server::Frontend::Frontend[frontend_identifier.downcase]
      frontend.backends = Backend.register :backends => config[:backends]

      frontend
    end
  end
end