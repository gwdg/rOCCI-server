require 'backends/dummy/entity_base'

module Backends
  module Dummy
    class Securitygroup < EntityBase
      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::InfrastructureExt::SecurityGroup
        end

        # :nodoc:
        def entity_identifier
          Occi::InfrastructureExt::Constants::SECURITY_GROUP_KIND
        end
      end

      # @see `Entitylike`
      def instance(identifier)
        instance = super
        instance['occi.securitygroup.rules'] = [{ protocol: 'tcp', range: '10.0.0.0/24', type: 'inbound' }]
        instance
      end
    end
  end
end
