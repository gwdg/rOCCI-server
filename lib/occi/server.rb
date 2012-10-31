require 'occi'
require 'occi/exceptions'

Encoding.default_external = Encoding::UTF_8 if defined? Encoding
Encoding.default_internal = Encoding::UTF_8 if defined? Encoding

module OCCI
  class Server
    VERSION = "0.5.0"

    def initialize()
      logger = Logger.new(STDERR)

      @log_subscriber = ActiveSupport::Notifications.subscribe("log") do |name, start, finish, id, payload|
        logger.log(payload[:level], payload[:message])
      end
             #ServerAmqp

    end

    def start(frontend_identifier = 'http', standalone = false)
      server_identifier = frontend_identifier.downcase + '_server'

      require "occi/frontend/#{server_identifier}"
      server_clazz = server_identifier.camelize

      @server = OCCI::Frontend.const_get(server_clazz).new(standalone)
      @server
    end
  end
end