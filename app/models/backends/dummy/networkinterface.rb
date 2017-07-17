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
    end
  end
end
