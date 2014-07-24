module Backends
  module Ec2
    module Helpers
      module NetworkParseHelper

        def network_parse_backend_obj(backend_network)
          network = Occi::Infrastructure::Network.new

          network.mixins << 'http://schemas.ec2.aws.amazon.com/occi/infrastructure/network#aws_ec2_vpc'

          network.attributes['occi.core.id'] = backend_network[:vpc_id]
          network.attributes['occi.core.title'] = if backend_network[:tags].select { |tag| tag[:key] == 'Name' }.any?
            backend_network[:tags].select { |tag| tag[:key] == 'Name' }.first[:value]
          else
            "rOCCI-server VPC #{backend_network[:cidr_block]}"
          end
          network.address = backend_network[:cidr_block] unless backend_network[:cidr_block].blank?
          network.attributes['occi.network.label'] = "AWS VPC #{backend_network[:vpc_id]}"

          network.attributes['com.amazon.aws.ec2.instance_tenancy'] = backend_network[:instance_tenancy] if backend_network[:instance_tenancy]
          network.attributes['com.amazon.aws.ec2.state'] = backend_network[:state] if backend_network[:state]
          network.attributes['com.amazon.aws.ec2.is_default'] = backend_network[:is_default] unless backend_network[:is_default].nil?

          # include state information and available actions
          result = network_parse_state(backend_network)
          network.state = result.state
          result.actions.each { |a| network.actions << a }

          network
        end

        private

        def network_parse_state(backend_network)
          result = Hashie::Mash.new

          # In EC2:
          #   pending | available
          case backend_network[:state]
          when 'available'
            result.state = 'online'
            result.actions = []
          else
            result.state = 'offline'
            result.actions = []
          end

          result
        end

        def network_get_raw(network_id)
          filters = []
          filters << { name: 'vpc-id', values: [network_id] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            vpcs = @ec2_client.describe_vpcs(filters: filters).vpcs
            vpcs ? vpcs.first : nil
          end
        end

      end
    end
  end
end
