module Backends
  module Errors
    # Exception class for generic REST underlying components
    class GenericRESTError < StandardError
      attr_accessor :code

      def initialize(code)
        @code = code
      end
    end
  end
end
