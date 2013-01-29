require 'occi'
require 'occi/server/helper/exceptions'
require "occi/server/helper/config"

Encoding.default_external = Encoding::UTF_8 if defined? Encoding
Encoding.default_internal = Encoding::UTF_8 if defined? Encoding

module Occi
  class Server
    VERSION = "0.9.0"

    def initialize()
      logger = Logger.new(STDERR)

      @log_subscriber = ActiveSupport::Notifications.subscribe("log") do |name, start, finish, id, payload|
        logger.log(payload[:level], payload[:message])
      end
    end

    # @param [String] frontend_identifier
    # @param [Boolean] standalone
    # @return [OCCI::Frontend::Server]
    def start(frontend_identifier = 'http')
      server
    end
  end
end