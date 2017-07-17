require 'backends/dummy/entity_base'

module Backends
  module Dummy
    class Storage < EntityBase
      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Storage
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::STORAGE_KIND
        end
      end
    end
  end
end
