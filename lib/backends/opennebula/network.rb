module Backends
  module Opennebula
    module Network

      # Gets all network instance IDs, no details, no duplicates. Returned
      # identifiers must corespond to those found in the occi.core.id
      # attribute of Occi::Infrastructure::Network instances.
      #
      # @example
      #    network_list_ids #=> []
      #    network_list_ids #=> ["65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf",
      #                             "ggf4f65adfadf-adgg4ad-daggad-fydd4fadyfdfd"]
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [Array<String>] IDs for all available network instances
      def network_list_ids(mixins = nil)
        # TODO: impl filtering with mixins
        backend_network_pool = ::OpenNebula::VirtualNetworkPool.new(@client)
        rc = backend_network_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        network = []
        backend_network_pool.each do |backend_network|
          network << backend_network['ID']
        end

        network
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
      def network_list(mixins = nil)
        # TODO: impl filtering with mixins
        network = Occi::Core::Resources.new
        backend_network_pool = ::OpenNebula::VirtualNetworkPool.new(@client)
        rc = backend_network_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        backend_network_pool.each do |backend_network|
          network << network_parse_backend_obj(backend_network)
        end

        network
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
      def network_get(network_id)
        virtual_network = ::OpenNebula::VirtualNetwork.new(::OpenNebula::VirtualNetwork.build_xml(network_id), @client)
        rc = virtual_network.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        network_parse_backend_obj(virtual_network)
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
      def network_create(network)
        @logger.debug "Creating network #{network.inspect}"
        template_location = File.join(@options.templates_dir, "network.erb")
        template = Erubis::Eruby.new(File.read(template_location)).evaluate({ :network => network })

        @logger.debug "Template #{template.inspect}"

        vnet_alloc = ::OpenNebula::VirtualNetwork.build_xml
        backend_object = ::OpenNebula::VirtualNetwork.new(vnet_alloc, @client)

        rc = backend_object.allocate(template)
        check_retval(rc, Backends::Errors::ResourceCreationError)

        rc = backend_object.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        backend_object['ID']
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
      def network_delete_all(mixins = nil)
        # TODO: impl filtering with mixins
        backend_network_pool = ::OpenNebula::VirtualNetworkPool.new(@client)
        rc = backend_network_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        backend_network_pool.each do |backend_network|
          rc = backend_network.delete
          check_retval(rc, Backends::Errors::ResourceActionError)
        end

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
      def network_delete(network_id)
        network = ::OpenNebula::VirtualNetwork.new(::OpenNebula::VirtualNetwork.build_xml(network_id), @client)
        rc = network.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        rc = network.delete
        check_retval(rc, Backends::Errors::ResourceActionError)

        true
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
      def network_update(network)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
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
      def network_trigger_action_on_all(action_instance, mixins = nil)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
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
      def network_trigger_action(network_id, action_instance)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      private

      def network_parse_backend_obj(backend_network)
        network = Occi::Infrastructure::Network.new

        # include some basic mixins
        network.mixins << 'http://opennebula.org/occi/infrastructure#network'

        # include mixins stored in ON's VN template
        unless backend_network['TEMPLATE/OCCI_NETWORK_MIXINS'].blank?
          backend_network_mixins = backend_network['TEMPLATE/OCCI_NETWORK_MIXINS'].split(' ')
          backend_network_mixins.each do |mixin|
            network.mixins << mixin unless mixin.blank?
          end
        end

        network.id    = backend_network['ID']
        network.title = backend_network['NAME'] if backend_network['NAME']
        network.summary = backend_network['TEMPLATE/DESCRIPTION'] if backend_network['TEMPLATE/DESCRIPTION']

        network.gateway = backend_network['TEMPLATE/GATEWAY'] if backend_network['TEMPLATE/GATEWAY']
        network.vlan = backend_network['VLAN_ID'].to_i if backend_network['VLAN_ID']

        unless backend_network['TEMPLATE/NETWORK_ADDRESS'].blank?
          network.allocation = "dynamic"

          if backend_network['TEMPLATE/NETWORK_ADDRESS'].include? '/'
            network.address = backend_network['TEMPLATE/NETWORK_ADDRESS']
          else
            unless backend_network['TEMPLATE/NETWORK_MASK'].blank?
              if backend_network['TEMPLATE/NETWORK_MASK'].include?('.')
                cidr = IPAddr.new(backend_network['TEMPLATE/NETWORK_MASK']).to_i.to_s(2).count("1")
                network.address = "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/#{cidr}"
              else
                network.address = "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/#{backend_network['TEMPLATE/NETWORK_MASK']}"
              end
            end
          end
        else
          network.allocation = "static"
        end

        network.attributes['org.opennebula.network.id'] = backend_network['ID']

        if backend_network['VLAN'].blank? || backend_network['VLAN'].to_i == 0
          network.attributes['org.opennebula.network.vlan'] = "NO"
        else
          network.attributes['org.opennebula.network.vlan'] = "YES"
        end

        network.attributes['org.opennebula.network.phydev'] = backend_network['PHYDEV'] unless backend_network['PHYDEV'].blank?
        network.attributes['org.opennebula.network.bridge'] = backend_network['BRIDGE'] unless backend_network['BRIDGE'].blank?

        if backend_network['RANGE']
          network.attributes['org.opennebula.network.ip_start'] = backend_network['RANGE/IP_START'] if backend_network['RANGE/IP_START']
          network.attributes['org.opennebula.network.ip_end'] = backend_network['RANGE/IP_END'] if backend_network['RANGE/IP_END']
        end

        result = network_parse_set_state(backend_network)
        network.state = result.state
        result.actions.each { |a| network.actions << a }

        network
      end

      def network_parse_set_state(backend_network)
        result = Hashie::Mash.new

        # ON doesn't implement actions on networks
        result.actions = []
        result.state = "active"

        result
      end

    end
  end
end