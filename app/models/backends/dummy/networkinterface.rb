require 'backends/dummy/base'

module Backends
  module Dummy
    class Networkinterface < Base
      include Entitylike

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Networkinterface
        end
      end
    end
  end
end
