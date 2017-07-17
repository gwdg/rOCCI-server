require 'backends/dummy/entity_base'

module Backends
  module Dummy
    class Network < EntityBase
      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Network
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::NETWORK_KIND
        end
      end
    end
  end
end
