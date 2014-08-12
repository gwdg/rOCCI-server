module Backends
  module Ec2
    module Helpers
      module ComputeNetworkHelper

        def compute_attach_network_public(networkinterface)
          compute_id = networkinterface.attributes['occi.core.source'].split('/').last

          # TODO: check for existing elastic addresses, not eni-0 interfaces
          compute_instance = compute_get(compute_id)
          fail Backends::Errors::ResourceCreationError, "Resource #{compute_id.inspect} already has a public network attached!" \
            if compute_instance.links.to_a.select { |l| l.id = "compute_#{compute_id}_nic_eni-0" }.any?

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            ec2_allocation = @ec2_client.allocate_address(domain: "standard")[:public_ip]

            begin
              @ec2_client.associate_address(
                instance_id: compute_id,
                public_ip: ec2_allocation
              )
            rescue => e
              @logger.warn "[Backends] [Ec2Backend] An attempt to associate #{ec2_allocation.inspect} with #{compute_id.inspect} failed!"
              @ec2_client.release_address(public_ip: ec2_allocation)
              fail Backends::Errors::ResourceCreationError, e.message
            end
          end

          "compute_#{compute_id}_nic_eni-0"
        end

        def compute_attach_network_private(networkinterface)
          # TODO: explore possible solutions
          fail Backends::Errors::ResourceCreationError, 'Network "private" cannot be attached manually!'
        end

        def compute_attach_network_vpc(networkinterface)
          # TODO: explore possible solutions
          fail Backends::Errors::ResourceCreationError, "VPC networks cannot be attached to already running instances!"
        end

        def compute_detach_network_public(networkinterface)
          # TODO: fix this! we cannot expect 'occi.networkinterface.address' to be set
          ec2_allocation = networkinterface.attributes['occi.networkinterface.address']
          fail Backends::Errors::ResourceCreationError, 'Interfaces without an address cannot be detached!' if ec2_allocation.blank?

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            begin
              @ec2_client.disassociate_address(public_ip: ec2_allocation)
              @ec2_client.release_address(public_ip: ec2_allocation)
            rescue ::Aws::EC2::Errors::AuthFailure => e
              @logger.warn "[Backends] [Ec2Backend] An attempt to release #{ec2_allocation.inspect} failed!"
              fail Backends::Errors::UserNotAuthorizedError, e.message
            end
          end
        end

        def compute_detach_network_private(networkinterface)
          fail Backends::Errors::ResourceCreationError, 'Network "private" cannot be detached manually!'
        end

        def compute_detach_network_vpc(networkinterface)
          # TODO: explore possible solutions
          fail Backends::Errors::ResourceCreationError, "VPC networks cannot be detached from already running instances!"
        end

      end
    end
  end
end
