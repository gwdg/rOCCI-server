module Backends
  class OpennebulaBackend
    API_VERSION = '0.0.1'

    def initialize(delegated_user, options, server_properties, logger, dalli_cache)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger
      @dalli_cache = dalli_cache

      @cloud_auth_client = init_connection(@delegated_user, @options)
      @client = nil

      @options.backend_scheme ||= "http://occi.#{@server_properties.hostname || 'localhost'}"

      path = @options.fixtures_dir || ''
      read_resource_tpl_fixtures(path)
    end

    def read_resource_tpl_fixtures(base_path)
      path = File.join(base_path, 'resource_tpl', '*.json')
      @resource_tpl = Occi::Core::Mixins.new

      Dir.glob(path) do |json_file|
        @resource_tpl.merge(read_from_json(json_file).mixins) if File.readable?(json_file)
      end
    end
    private :read_resource_tpl_fixtures

    def init_connection(delegated_user, options)
      conf = Hashie::Mash.new
      conf.auth = delegated_user.auth_.type
      conf.one_xmlrpc = options.xmlrpc_endpoint

      conf.srv_auth = 'cipher'
      conf.srv_user = options.username
      conf.srv_passwd = options.password

      Backends::Opennebula::Authn::CloudAuthClient.new(conf)
    end
    private :init_connection

    def check_retval(rc, e_klass)
      return true unless ::OpenNebula.is_error?(rc)

      case rc.errno
      when ::OpenNebula::Error::EAUTHENTICATION
        fail Backends::Errors::AuthenticationError, rc.message
      when ::OpenNebula::Error::EAUTHORIZATION
        fail Backends::Errors::UserNotAuthorizedError, rc.message
      when ::OpenNebula::Error::ENO_EXISTS
        fail Backends::Errors::ResourceNotFoundError, rc.message
      when ::OpenNebula::Error::EACTION
        fail Backends::Errors::ResourceStateError, rc.message
      else
        fail e_klass, rc.message
      end
    end
    private :check_retval

    # load helpers for JSON -> Collection conversion
    include Backends::Helpers::JsonCollectionHelper

    # load API implementation
    include Backends::Opennebula::Compute
    include Backends::Opennebula::Network
    include Backends::Opennebula::Storage
    include Backends::Opennebula::OsTpl
    include Backends::Opennebula::ResourceTpl

    # run authN code before every method
    extend Backends::Helpers::RunBeforeHelper::ClassMethods

    def run_authn
      return if @client

      username = @cloud_auth_client.auth(@delegated_user.auth_.credentials)
      fail Backends::Errors::AuthenticationError, 'User could not be authenticated!' if username.blank?

      @client = @cloud_auth_client.client(username)
      fail Backends::Errors::AuthenticationError, 'Could not get a client for the current user!' unless @client
    end
    private :run_authn

    run_before(instance_methods, :run_authn, true)
  end
end
