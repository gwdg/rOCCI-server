require 'backends/dummy/base'

module Backends
  module Dummy
    class ModelExtender < Base
      include Extenderlike

      # @see `Extenderlike`
      def populate!(model)
        Warehouse.bootstrap! model
      end
    end
  end
end
