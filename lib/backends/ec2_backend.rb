module Backends
  class Ec2Backend
    API_VERSION = '0.0.1'
    IMAGE_FILTERING_POLICIES = ['all', 'only_owned', 'only_listed', 'owned_and_listed'].freeze

    def initialize(delegated_user, options, server_properties, logger, dalli_cache)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger
      @dalli_cache = dalli_cache

      ::Aws.config[:region] = @options.aws_region || "eu-west-1"
      ::Aws.config[:endpoint] = @options.aws_endpoint unless @options.aws_endpoint.blank?
      @ec2_client = nil

      @options.backend_scheme ||= "http://occi.#{@server_properties.hostname || 'localhost'}"

      path = @options.fixtures_dir || ''
      read_resource_tpl_fixtures(path)

      set_image_filtering_policy
    end

    def set_image_filtering_policy
      policy = @options.image_filtering!.policy || 'all'
      image_list = @options.image_filtering!.image_list || []

      fail Backends::Errors::ConfigurationError, "Image policy #{policy.inspect} is not supported by the EC2 backend! #{IMAGE_FILTERING_POLICIES.inspect}" \
        unless IMAGE_FILTERING_POLICIES.include?(policy)

      fail Backends::Errors::ConfigurationError, "Image policies 'only_listed' and 'owned_and_listed' require a list of images!" \
        if (policy == 'only_listed' || policy == 'owned_and_listed') && image_list.blank?

      @logger.info "[Backends] [Ec2Backend] EC2 image filtering policy #{policy.inspect} with image list #{image_list.inspect}"

      @image_filtering_policy = policy
      @image_filtering_image_list = image_list.is_a?(Array) ? image_list : image_list.split(' ')
    end
    private :set_image_filtering_policy

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

      @ec2_client = ::Aws::EC2::Client.new(
        credentials: Backends::Ec2::Authn::Ec2CredentialsHelper.get_credentials(@options, @delegated_user, @logger),
        logger: @logger,
        log_level: :debug
      )
      fail Backends::Errors::AuthenticationError, 'Could not get an EC2 client for the current user!' unless @ec2_client
    end
    private :run_authn

    run_before(instance_methods, :run_authn, true)
  end
end
