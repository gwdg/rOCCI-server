module Backends
  class Dummy

    API_VERSION = "0.0.1"

    def initialize(options, server_properties, logger)
      @options = options || Hashie::Mash.new
      @server_properties = server_properties || Hashie::Mash.new
      @logger = logger || Rails.logger
    end

    include Backends::Compute::Dummy
    include Backends::Network::Dummy
    include Backends::Storage::Dummy
    include Backends::OsTpl::Dummy
    include Backends::ResourceTpl::Dummy

  end
end