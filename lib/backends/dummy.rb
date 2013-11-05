module Backends
  class Dummy

    def initialize(options = {}, server_properties = {})
      @options = options
      @server_properties = server_properties
    end

    include Backends::Compute::Dummy
    include Backends::Network::Dummy
    include Backends::Storage::Dummy
    include Backends::OsTpl::Dummy
    include Backends::ResourceTpl::Dummy

  end
end