module Backends
  module Ec2
    module Network

      NETWORK_DUMMIES = ['public', 'private'].freeze

      # Gets all network instance IDs, no details, no duplicates. Returned
      # identifiers must correspond to those found in the occi.core.id
      # attribute of Occi::Infrastructure::Network instances.
      #
      # @example
      #    network_list_ids #=> []
      #    network_list_ids #=> ["65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf",
      #                             "ggf4f65adfadf-adgg4ad-daggad-fydd4fadyfdfd"]
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [Array<String>] IDs for all available network instances
      # @effects Gets the status of existing VPC instances
      def network_list_ids(mixins = nil)
        id_list = []

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          vpcs = @ec2_client.describe_vpcs.vpcs
          vpcs.each { |vpc| id_list << vpc[:vpc_id] } if vpcs
        end

        id_list.concat(NETWORK_DUMMIES)

        id_list
      end

      # Gets all network instances, instances must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
      # Returned collection must contain Occi::Infrastructure::Network instances
      # wrapped in Occi::Core::Resources.
      #
      # @example
      #    networks = network_list #=> #<Occi::Core::Resources>
      #    networks.first #=> #<Occi::Infrastructure::Network>
      #
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    networks = network_list(mixins) #=> #<Occi::Core::Resources>
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [Occi::Core::Resources] a collection of network instances
      # @effects Gets the status of existing VPC instances
      def network_list(mixins = nil)
        networks = Occi::Core::Resources.new

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          vpcs = @ec2_client.describe_vpcs.vpcs
          vpcs.each { |vpc| networks << network_parse_backend_obj(vpc) } if vpcs
        end

        networks << network_get_dummy_public << network_get_dummy_private

        networks
      end

      # Gets a specific network instance as Occi::Infrastructure::Network.
      # ID given as an argument must match the occi.core.id attribute inside
      # the returned Occi::Infrastructure::Network instance, however it is possible
      # to implement internal mapping to a platform-specific identifier.
      #
      # @example
      #    network = network_get('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<Occi::Infrastructure::Network>
      #
      # @param network_id [String] OCCI identifier of the requested network instance
      # @return [Occi::Infrastructure::Network, nil] a network instance or `nil`
      # @effects Gets status of the given VPC
      def network_get(network_id)
        return network_get_dummy_public if network_id == 'public'
        return network_get_dummy_private if network_id == 'private'

        vpc = network_get_raw(network_id)
        vpc ? network_parse_backend_obj(vpc) : nil
      end

      # Instantiates a new network instance from Occi::Infrastructure::Network.
      # ID given in the occi.core.id attribute is optional and can be changed
      # inside this method. Final occi.core.id must be returned as a String.
      # If the requested instance cannot be created, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    network = Occi::Infrastructure::Network.new
      #    network_id = network_create(network)
      #        #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
      #
      # @param network [Occi::Infrastructure::Network] network instance containing necessary attributes
      # @return [String] final identifier of the new network instance
      # @effects Creates a VPC
      # @effects Creates a subnet and creates tags for it
      # @effects Creates a new Internet gateway nd creates tags for it
      # @effects Attaches the Internet gateway to the VPC
      def network_create(network)
        fail Backends::Errors::UserNotAuthorizedError, "Creating networks has been disabled in server's configuration!" \
          unless @options.network_create_allowed

        fail Backends::Errors::ResourceNotValidError, "Network address in CIDR notation is required!" if network.address.blank?
        tags = []
        tags << { key: 'Name', value: (network.title || "rOCCI-server VPC #{network.address}") }

        vpc = nil
        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          vpc = @ec2_client.create_vpc(
            cidr_block: network.address,
            instance_tenancy: "default"
          ).vpc

          vpc_subnet = @ec2_client.create_subnet(
            vpc_id: vpc[:vpc_id],
            cidr_block: network.address,
            availability_zone: @options.aws_availability_zone
          ).subnet

          @ec2_client.create_tags(
            resources: [vpc[:vpc_id], vpc_subnet[:subnet_id]],
            tags: tags
          )
        end

        network_create_add_igw(vpc[:vpc_id], tags)

        vpc[:vpc_id]
      end

      # Deletes all network instances, instances to be deleted must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
      # If the requested instances cannot be deleted, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    network_delete_all #=> true
      #
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    network_delete_all(mixins)  #=> true
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [true, false] result of the operation
      # @effects Deletes all items for all VPCs (security groups, internet gateways, VPN gateways, ACLs, routing tables, subnets, and DHCP options)
      # @effects Deletes all VPCs
      def network_delete_all(mixins = nil)
        vpc_ids = network_list_ids(mixins) - NETWORK_DUMMIES
        vpc_ids.each { |vpc_id| network_delete(vpc_id) }

        true
      end

      # Deletes a specific network instance, instance to be deleted is
      # specified by an ID, this ID must match the occi.core.id attribute
      # of the deleted instance.
      # If the requested instance cannot be deleted, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    network_delete("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param network_id [String] an identifier of a network instance to be deleted
      # @return [true, false] result of the operation
      # @effects Gets status of the given VPC
      # @effects Deletes all items for a given VPC (security groups, internet gateways, VPN gateways, ACLs, routing tables, subnets, and DHCP options)
      # @effects Deletes the given VPC
      def network_delete(network_id)
        fail Backends::Errors::UserNotAuthorizedError, "Deleting networks has been disabled in server's configuration!" \
          unless @options.network_destroy_allowed

        fail Backends::Errors::UserNotAuthorizedError, "You cannot delete EC2-provided networks! [#{network_id.inspect}]" \
          if NETWORK_DUMMIES.include?(network_id)

        vpc = network_get_raw(network_id)
        fail Backends::Errors::ResourceNotFoundError, "The VPC #{network_id.inspect} does not exist." unless vpc

        network_delete_security_groups(vpc)
        network_delete_internet_gateways(vpc)
        network_delete_vpn_gateways(vpc)
        network_delete_acls(vpc)
        network_delete_route_tables(vpc)
        network_delete_subnets(vpc)

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          @ec2_client.delete_vpc(vpc_id: network_id)
        end

        network_delete_dhcp_options(vpc)

        true
      end

      # Partially updates an existing network instance, instance to be updated
      # is specified by network_id.
      # If the requested instance cannot be updated, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    attributes = Occi::Core::Attributes.new
      #    mixins = Occi::Core::Mixins.new
      #    links = Occi::Core::Links.new
      #    network_partial_update(network_id, attributes, mixins, links) #=> true
      #
      # @param network_id [String] unique identifier of a network instance to be updated
      # @param attributes [Occi::Core::Attributes] a collection of attributes to be updated
      # @param mixins [Occi::Core::Mixins] a collection of mixins to be added
      # @param links [Occi::Core::Links] a collection of links to be added
      # @return [true, false] result of the operation
      # @todo Not supported
      def network_partial_update(network_id, attributes = nil, mixins = nil, links = nil)
        fail Backends::Errors::MethodNotImplementedError, 'Partial updates are currently not supported!'
      end

      # Updates an existing network instance, instance to be updated is specified
      # using the occi.core.id attribute of the instance passed as an argument.
      # If the requested instance cannot be updated, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    network = Occi::Infrastructure::Network.new
      #    network_update(network) #=> true
      #
      # @param network [Occi::Infrastructure::Network] instance containing updated information
      # @return [true, false] result of the operation
      # @todo Not implemented
      def network_update(network)
        fail Backends::Errors::MethodNotImplementedError, 'Not Implemented!'
      end

      # Triggers an action on all existing network instance, instances must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance,
      # action is identified by the action.term attribute of the action instance passed as an argument.
      # If the requested action cannot be triggered, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    action_instance = Occi::Core::ActionInstance.new
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    network_trigger_action_on_all(action_instance, mixin) #=> true
      #
      # @param action_instance [Occi::Core::ActionInstance] action to be triggered
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [true, false] result of the operation
      # @todo Underlying method not implemented
      def network_trigger_action_on_all(action_instance, mixins = nil)
        network_list_ids(mixins).each { |ntwrk| network_trigger_action(ntwrk, action_instance) }
        true
      end

      # Triggers an action on an existing network instance, the network instance in question
      # is identified by a network instance ID, action is identified by the action.term attribute
      # of the action instance passed as an argument.
      # If the requested action cannot be triggered, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    action_instance = Occi::Core::ActionInstance.new
      #    network_trigger_action("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf", action_instance)
      #      #=> true
      #
      # @param network_id [String] network instance identifier
      # @param action_instance [Occi::Core::ActionInstance] action to be triggered
      # @return [true, false] result of the operation
      # @todo Not implemented
      def network_trigger_action(network_id, action_instance)
        fail Backends::Errors::ActionNotImplementedError,
             "Action #{action_instance.action.type_identifier.inspect} is not implemented!"
        true
      end

      private

      # Load methods called from network_list/network_get
      include Backends::Ec2::Helpers::NetworkParseHelper

      # Load methods called from network_delete
      include Backends::Ec2::Helpers::NetworkDeleteHelper

      # Load methods called from network_create
      include Backends::Ec2::Helpers::NetworkCreateHelper

      # Load methods called for dummy networks from network_get/network_list
      include Backends::Ec2::Helpers::NetworkDummyHelper
    end
  end
end
