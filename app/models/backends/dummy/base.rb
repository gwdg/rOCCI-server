module Backends
  module Dummy
    class Base
      API_VERSION = '3.0.0'.freeze

      attr_reader :options
      delegate :api_version, to: :class

      def initialize(options = {})
        @options = options
      end

      class << self
        def api_version
          API_VERSION
        end
      end
    end
  end
end
