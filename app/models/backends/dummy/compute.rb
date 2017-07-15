require 'backends/dummy/base'

module Backends
  module Dummy
    class Compute < Base
      include Entitylike

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Compute
        end
      end
    end
  end
end
