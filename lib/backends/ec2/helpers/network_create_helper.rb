module Backends
  module Ec2
    module Helpers
      module NetworkCreateHelper

        def network_create_add_igw(vpc_id, tags)
          igw_id = network_create_get_igw(tags)

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            @ec2_client.attach_internet_gateway(
              internet_gateway_id: igw_id,
              vpc_id: vpc_id
            )
          end
        end

        private

        def network_create_get_igw(tags)
          internet_gateway = nil
          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            internet_gateway = @ec2_client.create_internet_gateway.internet_gateway

            @ec2_client.create_tags(
              resources: [internet_gateway[:internet_gateway_id]],
              tags: tags
            )
          end

          internet_gateway[:internet_gateway_id]
        end

      end
    end
  end
end
