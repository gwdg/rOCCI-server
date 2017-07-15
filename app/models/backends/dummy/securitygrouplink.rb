require 'backends/dummy/base'

module Backends
  module Dummy
    class Securitygrouplink < Base
      include Entitylike

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::InfrastructureExt::SecurityGroupLink
        end
      end
    end
  end
end
