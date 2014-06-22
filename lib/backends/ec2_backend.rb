module Backends
  class Ec2Backend
    API_VERSION = '0.0.1'

    def initialize(delegated_user, options, server_properties, logger, dalli_cache)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger
      @dalli_cache = dalli_cache
    end

    # load API implementation
    include Backends::Ec2::Compute
    include Backends::Ec2::Network
    include Backends::Ec2::Storage
    include Backends::Ec2::OsTpl
    include Backends::Ec2::ResourceTpl
  end
end
