module Backends
  module Ec2
    module Helpers
      module NetworkDummyHelper

        def network_get_dummy_public
          network_get_dummy :public
        end

        def network_get_dummy_private
          network_get_dummy :private
        end

        private

        def network_get_dummy(type)
          network = Occi::Infrastructure::Network.new
          network.mixins << 'http://schemas.ogf.org/occi/infrastructure/network#ipnetwork'

          network.id = type.to_s
          network.title = "Generated network representing EC2's #{type.to_s} address range"
          network.state = 'active'
          network.label = type.to_s

          network
        end

      end
    end
  end
end
