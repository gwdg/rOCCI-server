require 'backends/dummy/base'

module Backends
  module Dummy
    class Storagelink < Base
      include Entitylike

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Storagelink
        end
      end
    end
  end
end
