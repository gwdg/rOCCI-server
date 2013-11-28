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

      path = @options.fixtures_dir || ""
      read_resource_tpl_fixtures(path)
    end

    def self.auth_before(*names)
      names.each do |name|
        next unless needs_auth?(name)

        m = instance_method(name)
        define_method(name) do |*args, &block|
          unless @client
            username = @cloud_auth_client.auth(@delegated_user.auth_.credentials)
            raise Backends::Errors::AuthenticationError, "User could not be authenticated!" if username.blank?

            @client = @cloud_auth_client.client(username)
            raise Backends::Errors::AuthenticationError, "Could not get a client for the current user!" unless @client
          end

          m.bind(self).(*args, &block)
        end
      end
    end

    def self.needs_auth?(name)
      name.to_s.match /compute_|network_|os_tpl_|resource_tpl_|storage_/
    end

    def read_resource_tpl_fixtures(base_path)
      path = File.join(base_path, "resource_tpl", "*.json")
      @resource_tpl = Occi::Core::Mixins.new

      Dir.glob(path) do |json_file|
        @resource_tpl.merge(read_from_json(json_file).mixins) if File.readable?(json_file)
      end
    end
    private :read_resource_tpl_fixtures

    # load helpers for JSON -> Collection conversion
    include Backends::Helpers::JsonCollectionHelper

    # load API implementation
    include Backends::Opennebula::Compute
    include Backends::Opennebula::Network
    include Backends::Opennebula::Storage
    include Backends::Opennebula::OsTpl
    include Backends::Opennebula::ResourceTpl

    # TODO: does not work!
    auth_before(*instance_methods)

  end
end