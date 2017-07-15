require 'backends/dummy/base'

module Backends
  module Dummy
    class Securitygroup < Base
      include Entitylike

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::InfrastructureExt::SecurityGroup
        end
      end
    end
  end
end
