require 'backends/dummy/base'

module Backends
  module Dummy
    class ModelExtension < Base
      def populate!(model)
        # there are no extensions to add here
        model
      end
    end
  end
end
