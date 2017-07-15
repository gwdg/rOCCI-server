require 'backends/dummy/base'

module Backends
  module Dummy
    class Storage < Base
      include Entitylike

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Storage
        end
      end
    end
  end
end
