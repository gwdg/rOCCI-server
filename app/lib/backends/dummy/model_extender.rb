require 'backends/dummy/entity_base'

module Backends
  module Dummy
    class ModelExtender < Base
      include Helpers::Extenderlike

      # @see `Extenderlike`
      def populate!(model)
        Warehouse.bootstrap! model
      end
    end
  end
end
