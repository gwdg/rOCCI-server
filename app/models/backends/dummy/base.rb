module Backends
  module Dummy
    class Base
      API_VERSION = '3.0.0'.freeze

      attr_reader :options

      def initialize(options = {})
        @options = options
      end
    end
  end
end
