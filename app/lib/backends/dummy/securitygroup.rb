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
    end
  end
end
