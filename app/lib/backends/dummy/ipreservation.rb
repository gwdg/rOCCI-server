require 'backends/dummy/entity_base'

module Backends
  module Dummy
    class Ipreservation < EntityBase
      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::InfrastructureExt::IPReservation
        end

        # :nodoc:
        def entity_identifier
          Occi::InfrastructureExt::Constants::IPRESERVATION_KIND
        end
      end

      # @see `Entitylike`
      def instance(identifier)
        instance = super
        instance['occi.ipreservation.address'] = IPAddr.new('10.0.0.1')
        instance
      end
    end
  end
end
