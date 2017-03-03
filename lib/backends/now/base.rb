module Backends
  module Now
    # Base class for all backends
    class Base
      API_VERSION = '2.0.0'.freeze

      # load helpers for JSON -> Collection conversion
      include Backends::Helpers::JsonCollectionHelper

      attr_reader :options

      def initialize(delegated_user, options, server_properties, logger, dalli_cache)
        @delegated_user = Hashie::Mash.new(delegated_user)
        @options = Hashie::Mash.new(options)
        @server_properties = Hashie::Mash.new(server_properties)
        @logger = logger || Rails.logger
        @dalli_cache = dalli_cache
        @other_backends = {}
      end

      def add_other_backend(backend_type, backend_instance)
        raise 'Type and instance must be provided!' unless backend_type && backend_instance
        @other_backends[backend_type] = backend_instance
      end
    end
  end
end
