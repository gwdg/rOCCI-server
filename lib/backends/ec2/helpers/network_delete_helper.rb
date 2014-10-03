module Backends
  module Ec2
    module Helpers
      module NetworkDeleteHelper

        def network_delete_dhcp_options(vpc)
          return false if vpc[:dhcp_options_id].blank?

          filters = []
          filters << { name: 'dhcp-options-id', values: [vpc[:dhcp_options_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            vpcs = @ec2_client.describe_vpcs(filters: filters).vpcs
            @ec2_client.delete_dhcp_options(dhcp_options_id: vpc[:dhcp_options_id]) if vpcs.blank?
          end

          true
        end

        def network_delete_route_tables(vpc)
          filters = []
          filters << { name: 'vpc-id', values: [vpc[:vpc_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            route_tables = @ec2_client.describe_route_tables(filters: filters).route_tables
            route_tables.each do |route_table|
              is_main = false
              route_table[:associations].each do |assoc|
                next if assoc[:main] && (is_main = true)
                @ec2_client.disassociate_route_table(association_id: assoc[:route_table_association_id])
              end

              @ec2_client.delete_route_table(route_table_id: route_table[:route_table_id]) unless is_main
            end if route_tables
          end

          true
        end

        def network_delete_acls(vpc)
          filters = []
          filters << { name: 'vpc-id', values: [vpc[:vpc_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            network_acls = @ec2_client.describe_network_acls(filters: filters).network_acls
            network_acls.each do |network_acl|
              next if network_acl[:is_default]
              @ec2_client.delete_network_acl(network_acl_id: network_acl[:network_acl_id])
            end if network_acls
          end

          true
        end

        def network_delete_security_groups(vpc)
          filters = []
          filters << { name: 'vpc-id', values: [vpc[:vpc_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            security_groups = @ec2_client.describe_security_groups(filters: filters).security_groups
            security_groups.each do |security_group|
              next if security_group[:group_name] == 'default'
              @ec2_client.delete_security_group(group_id: security_group[:group_id])
            end if security_groups
          end

          true
        end

        def network_delete_internet_gateways(vpc)
          filters = []
          filters << { name: 'attachment.vpc-id', values: [vpc[:vpc_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            internet_gateways = @ec2_client.describe_internet_gateways(filters: filters).internet_gateways
            internet_gateways.each do |internet_gateway|
              @ec2_client.detach_internet_gateway(internet_gateway_id: internet_gateway[:internet_gateway_id], vpc_id: vpc[:vpc_id])
              @ec2_client.delete_internet_gateway(internet_gateway_id: internet_gateway[:internet_gateway_id]) if internet_gateway[:attachments].length == 1
            end if internet_gateways
          end

          true
        end

        def network_delete_vpn_gateways(vpc)
          filters = []
          filters << { name: 'attachment.vpc-id', values: [vpc[:vpc_id]] }
          filters << { name: 'attachment.state', values: ['attached'] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            vpn_gateways = @ec2_client.describe_vpn_gateways(filters: filters).vpn_gateways
            vpn_gateways.each do |vpn_gateway|
              @ec2_client.detach_vpn_gateway(vpn_gateway_id: vpn_gateway[:vpn_gateway_id], vpc_id: vpc[:vpc_id])
              network_delete_vpn_gateways_wait4detach(vpn_gateway, vpc[:vpc_id])

              if @options.network_destroy_vpn_gws
                network_delete_vpn_connections(vpn_gateway)
                @ec2_client.delete_vpn_gateway(vpn_gateway_id: vpn_gateway[:vpn_gateway_id]) if vpn_gateway[:vpc_attachments].length == 1
              end
            end if vpn_gateways
          end

          true
        end

        def network_delete_subnets(vpc)
          filters = []
          filters << { name: 'vpc-id', values: [vpc[:vpc_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            subnets = @ec2_client.describe_subnets(filters: filters).subnets
            subnets.each { |subnet| @ec2_client.delete_subnet(subnet_id: subnet[:subnet_id]) } if subnets
          end

          true
        end

        def network_delete_vpn_connections(vpn_gateway)
          filters = []
          filters << { name: 'vpn-gateway-id', values: [vpn_gateway[:vpn_gateway_id]] }

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            vpn_connections = @ec2_client.describe_vpn_connections(filters: filters).vpn_connections
            vpn_connections.each { |vpn_connection| @ec2_client.delete_vpn_connection(vpn_connection_id: vpn_connection[:vpn_connection_id]) } if vpn_connections
          end

          network_delete_vpn_connections_wait4detach(vpn_gateway)

          true
        end

        def network_delete_vpn_gateways_wait4detach(vpn_gateway, vpc_id)
          return false unless vpn_gateway && vpc_id

          # TODO: use @ec2_client.wait_until if a waiter becomes available
          filters = []
          filters << { name: 'vpn-gateway-id', values: [vpn_gateway[:vpn_gateway_id]] }
          filters << { name: 'attachment.vpc-id', values: [vpc_id] }
          filters << { name: 'attachment.state', values: ['attaching', 'attached', 'detaching'] }

          until vpn_gateway.blank?
            sleep 5.0

            Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
              vpn_gateways = @ec2_client.describe_vpn_gateways(filters: filters).vpn_gateways
              vpn_gateway = vpn_gateways ? vpn_gateways.first : nil
            end
          end

          true
        end

        def network_delete_vpn_connections_wait4detach(vpn_gateway)
          return false unless vpn_gateway

          # TODO: use @ec2_client.wait_until if a waiter becomes available
          filters = []
          filters << { name: 'vpn-gateway-id', values: [vpn_gateway[:vpn_gateway_id]] }
          filters << { name: 'state', values: ['pending', 'deleting'] }

          vpn_connection = 'dummy'
          until vpn_connection.blank?
            sleep 5.0

            Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
              vpn_connections = @ec2_client.describe_vpn_connections(filters: filters).vpn_connections
              vpn_connection = vpn_connections ? vpn_connections.first : nil
            end
          end

          true
        end

      end
    end
  end
end
