module Backends
  class OpennebulaBackend

    API_VERSION = "0.0.1"

    def initialize(delegated_user, options, server_properties, logger)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger

      conf = Hashie::Mash.new
      conf.auth = @delegated_user.auth_.type
      conf.one_xmlrpc = @options.xmlrpc_endpoint

      conf.srv_auth = "cipher"
      conf.srv_user = @options.username
      conf.srv_passwd = @options.password

      @cloud_auth_client = Backends::Opennebula::Authn::CloudAuthClient.new(conf)
      @client = nil
    end

    def self.before(*names)
      names.each do |name|
        next unless needs_auth?(name)

        m = instance_method(name)
        define_method(name) do |*args, &block|
          yield
          m.bind(self).(*args, &block)
        end
      end
    end

    def self.needs_auth?(name)
      name.to_s.match /compute_|network_|os_tpl_|resource_tpl_|storage_/
    end

    # load API implementation
    include Backends::Opennebula::Compute
    include Backends::Opennebula::Network
    include Backends::Opennebula::Storage
    include Backends::Opennebula::OsTpl
    include Backends::Opennebula::ResourceTpl

    before(*instance_methods) {
      unless @client
        username = @cloud_auth_client.auth(@delegated_user.auth_.credentials)
        raise Backends::Errors::AuthenticationError, "User could not be authenticated!" if username.blank?

        @client = @cloud_auth_client.client(username)
      end
    }

  end
end