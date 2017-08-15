require 'backends/dummy/entity_base'

module Backends
  module Dummy
    class Networkinterface < EntityBase
      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Networkinterface
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::NETWORKINTERFACE_KIND
        end
      end

      # @see `Entitylike`
      def instance(identifier)
        instance = super
        instance['occi.core.source'] = URI.parse '/compute/a262ad95-c093-4814-8c0d-bc6d475bb845'
        instance['occi.core.target'] = URI.parse '/network/8b3e4362-b761-4eed-a6f3-69e271f90286'
        instance.target_kind = find_by_identifier!(
          Occi::Infrastructure::Constants::NETWORK_KIND
        )
        instance
      end
    end
  end
end
