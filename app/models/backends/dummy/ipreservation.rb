require 'backends/dummy/base'

module Backends
  module Dummy
    class Ipreservation < Base
      include Entitylike

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::InfrastructureExt::IPReservation
        end
      end
    end
  end
end
