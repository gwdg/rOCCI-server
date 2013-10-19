module Backends
  module Helpers
    module MethodMissingHelper

      def method_missing(m, *args, &block)
        raise Backends::Errors::MethodNotImplementedError, "Method is not implemented in the #{self.class.to_s} backend! [#{m}]"
      end

    end
  end
end