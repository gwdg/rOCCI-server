require 'backends/dummy/entity_base'

module Backends
  module Dummy
    class Storagelink < EntityBase
      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Storagelink
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::STORAGELINK_KIND
        end
      end
    end
  end
end
