require 'backends/dummy/base'

module Backends
  module Dummy
    class Network < Base
      include Entitylike

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Network
        end
      end
    end
  end
end
