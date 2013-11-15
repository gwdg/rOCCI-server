module Backends
  class Opennebula

    API_VERSION = "0.0.1"

    def initialize(delegated_user, options, server_properties, logger)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger
    end

  end
end