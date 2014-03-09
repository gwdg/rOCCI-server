module Backends
  module Helpers
    module MethodMissingHelper
      def method_missing(m, *args, &block)
        if m.to_s.match(/^(compute_|network_|os_tpl_|resource_tpl_|storage_).+/)
          fail Backends::Errors::MethodNotImplementedError, "Method is not implemented in the #{self.class.to_s} backend! [#{m}]"
        else
          super # This has to be here! Look at the previous line in the backtrace to find out what really happened!
        end
      end
    end
  end
end
