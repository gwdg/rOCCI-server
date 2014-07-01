module Backends
  module Ec2
    module Helpers
      module NetworkDeleteHelper

        def network_delete_dhcp_options(vpc)
          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            @ec2_client.delete_dhcp_options(dhcp_options_id: vpc[:dhcp_options_id]) if vpc[:dhcp_options_id]
          end

          true
        end

        def network_delete_route_tables(vpc)
          filters = []
          filters << { name: 'vpc-id', values: [vpc[:vpc_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            route_tables = @ec2_client.describe_route_tables(filters: filters).route_tables
            route_tables.each { |route_table| @ec2_client.delete_route_table(route_table_id: route_table[:route_table_id]) } if route_tables
          end

          true
        end

        def network_delete_acls(vpc)
          filters = []
          filters << { name: 'vpc-id', values: [vpc[:vpc_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            network_acls = @ec2_client.describe_network_acls(filters: filters).network_acls
            network_acls.each { |network_acl| @ec2_client.delete_network_acl(network_acl_id: network_acl[:network_acl_id]) } if network_acls
          end

          true
        end

      end
    end
  end
end
