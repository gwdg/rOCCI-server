module Backends
  class Opennebula

    API_VERSION = "0.0.1"

    def initialize(options, server_properties, logger)
      @options = options || Hashie::Mash.new
      @server_properties = server_properties || Hashie::Mash.new
      @logger = logger || Rails.logger
    end

  end
end