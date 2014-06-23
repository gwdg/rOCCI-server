module Backends
  class Ec2Backend
    API_VERSION = '0.0.1'

    def initialize(delegated_user, options, server_properties, logger, dalli_cache)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger
      @dalli_cache = dalli_cache

      ::Aws.config[:region] = @options.aws_region || "us-east-1"
      @ec2_client = nil

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

    # load helpers for JSON -> Collection conversion
    include Backends::Helpers::JsonCollectionHelper

    # load API implementation
    include Backends::Ec2::Compute
    include Backends::Ec2::Network
    include Backends::Ec2::Storage
    include Backends::Ec2::OsTpl
    include Backends::Ec2::ResourceTpl

    # run authN code before every method
    extend Backends::Helpers::RunBeforeHelper::ClassMethods

    def run_authn
      return if @ec2_client
      fail Backends::Errors::AuthenticationError, 'User could not be authenticated, access_key_id is missing!' if @options.access_key_id.blank?
      fail Backends::Errors::AuthenticationError, 'User could not be authenticated, secret_access_key is missing!' if @options.secret_access_key.blank?

      @ec2_client = ::Aws::EC2.new(
        credentials: ::Aws::Credentials.new(@options.access_key_id, @options.secret_access_key),
        logger: @logger,
        log_level: :debug
      )
      fail Backends::Errors::AuthenticationError, 'Could not get an EC2 client for the current user!' unless @ec2_client
    end
    private :run_authn

    run_before(instance_methods, :run_authn, true)
  end
end
