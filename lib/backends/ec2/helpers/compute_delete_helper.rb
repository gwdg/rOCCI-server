module Backends
  module Ec2
    module Helpers
      module ComputeDeleteHelper

        # TODO: look for ways to DRY this up by re-using ComputeNetworkHelper

        def compute_delete_release_public(instance_ids)
          filters = []
          filters << { name: 'instance-id', values: instance_ids }

          addresses = nil
          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            addresses = @ec2_client.describe_addresses(filters: filters).addresses
            addresses.each do |address|
              if address[:allocation_id] && address[:association_id]
                compute_delete_release_public_vpc(address)
              else
                compute_delete_release_public_nonvpc(address)
              end
            end
          end
        end

        private

        def compute_delete_release_public_vpc(address)
          @ec2_client.disassociate_address(association_id: address[:association_id])
          @ec2_client.release_address(allocation_id: address[:allocation_id])
        end

        def compute_delete_release_public_nonvpc(address)
          @ec2_client.disassociate_address(public_ip: address[:public_ip])
          @ec2_client.release_address(public_ip: address[:public_ip])
        end

      end
    end
  end
end
