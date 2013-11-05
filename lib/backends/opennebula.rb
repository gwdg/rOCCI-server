module Backends
  class Opennebula

    def initialize(options = Hashie::Mash.new, server_properties = Hashie::Mash.new)
      @options = options
      @server_properties = server_properties
    end

  end
end