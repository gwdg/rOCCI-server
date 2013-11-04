module Backends
  class Opennebula

    def initialize(options = {}, server_properties = {})
      @options = options
      @server_properties = server_properties
    end

    #include Backends::Model::Opennebula
    include Backends::Model::Dummy

  end
end