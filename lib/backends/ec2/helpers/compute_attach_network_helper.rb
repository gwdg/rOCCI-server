module Backends
  module Ec2
    module Helpers
      module ComputeAttachNetworkHelper

        def compute_attach_network_public(networkinterface)
          compute_id = networkinterface.attributes['occi.core.source'].split('/').last

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
              @logger.warn "[Backends] [Ec2Backend] Attempting to release #{ec2_allocation.inspect} after attaching to #{compute_id.inspect} failed!"
              @ec2_client.release_address(public_ip: ec2_allocation)
              fail Backends::Errors::ResourceCreationError, e.message
            end
          end

          "compute_#{compute_id}_nic_eni-0"
        end

        def compute_attach_network_private(networkinterface)
          fail Backends::Errors::ResourceCreationError, 'Network "private" cannot be attached manually!'
        end

        def compute_attach_network_vpc(networkinterface)
          # TODO: handle VPC, subnet selection, intf. creation and attaching
        end

      end
    end
  end
end
