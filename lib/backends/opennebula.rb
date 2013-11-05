module Backends
  class Opennebula

    API_VERSION = "0.0.1"

    def initialize(options = Hashie::Mash.new, server_properties = Hashie::Mash.new)
      @options = options
      @server_properties = server_properties
    end

  end
end