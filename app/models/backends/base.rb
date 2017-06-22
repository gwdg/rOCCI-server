module Backends
  class Base
    attr_reader :options, :logger, :backend_proxy
    delegate :api_version, to: :class

    def initialize(args = {})
      pre_initialize(args)

      @options = args
      @logger = args.fetch(:logger)
      @backend_proxy = args.fetch(:backend_proxy)

      post_initialize(args)
    end

    class << self
      def api_version
        self::API_VERSION
      end
    end

    protected

    # :nodoc:
    def pre_initialize(args); end

    # :nodoc:
    def post_initialize(args); end
  end
end
