module Backends
  module Ec2
    class Base
      API_VERSION = '1.0.0'
      IMAGE_FILTERING_POLICIES = ['all', 'only_owned', 'only_listed', 'owned_and_listed'].freeze

      # load helpers for JSON -> Collection conversion
      include Backends::Helpers::JsonCollectionHelper

      def initialize(delegated_user, options, server_properties, logger, dalli_cache)
        @delegated_user = Hashie::Mash.new(delegated_user)
        @options = Hashie::Mash.new(options)
        @server_properties = Hashie::Mash.new(server_properties)
        @logger = logger || Rails.logger
        @dalli_cache = dalli_cache
        @other_backends = {}
        @ec2_client = nil

        # establish connection with AWS
        ::Aws.config[:region] = @options.aws_region || "eu-west-1"
        ::Aws.config[:endpoint] = @options.aws_endpoint unless @options.aws_endpoint.blank?
        run_authn unless Rails.env.test? # disable early auth for tests

        @options.backend_scheme ||= "http://occi.#{@server_properties.hostname || 'localhost'}"

        path = @options.fixtures_dir || ''
        read_resource_tpl_fixtures(path)

        set_image_filtering_policy
      end

      def add_other_backend(backend_type, backend_instance)
        fail 'Type and instance must be provided!' unless backend_type && backend_instance
        @other_backends[backend_type] = backend_instance
      end

      private

      # load helpers for working with OCCI extensions
      include Backends::Helpers::ExtensionsHelper

      def set_image_filtering_policy
        policy = @options.image_filtering!.policy || 'all'
        image_list = @options.image_filtering!.image_list || []

        fail Backends::Errors::ConfigurationError, "Image policy #{policy.inspect} is not supported by the EC2 backend! #{IMAGE_FILTERING_POLICIES.inspect}" \
        unless IMAGE_FILTERING_POLICIES.include?(policy)

        fail Backends::Errors::ConfigurationError, "Image policies 'only_listed' and 'owned_and_listed' require a list of images!" \
        if (policy == 'only_listed' || policy == 'owned_and_listed') && image_list.blank?

        @logger.info "[Backends] [Ec2] EC2 image filtering policy #{policy.inspect} with image list #{image_list.inspect}"

        @image_filtering_policy = policy
        @image_filtering_image_list = image_list.is_a?(Array) ? image_list : image_list.split(' ')
      end

      def read_resource_tpl_fixtures(base_path)
        path = File.join(base_path, 'resource_tpl', '*.json')
        @resource_tpl = ::Occi::Core::Mixins.new

        Dir.glob(path) do |json_file|
          @resource_tpl.merge(read_from_json(json_file).mixins) if File.readable?(json_file)
        end
      end

      def run_authn
        return if @ec2_client

        @ec2_client = ::Aws::EC2::Client.new(
            credentials: Backends::Ec2::Authn::Ec2CredentialsHelper.get_credentials(@options, @delegated_user, @logger),
            logger: @logger,
            log_level: :debug
        )
        fail Backends::Errors::AuthenticationError, 'Could not get an EC2 client for the current user!' unless @ec2_client
      end
    end
  end
end
