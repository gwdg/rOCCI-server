module Backends
  module Opennebula
    module Compute

      STORAGE_GENERATED_PREFIX = "generated_"
      NETWORK_GENERATED_PREFIX = "generated_"

      # Gets all compute instance IDs, no details, no duplicates. Returned
      # identifiers must corespond to those found in the occi.core.id
      # attribute of Occi::Infrastructure::Compute instances.
      #
      # @example
      #    compute_list_ids #=> []
      #    compute_list_ids #=> ["65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf",
      #                             "ggf4f65adfadf-adgg4ad-daggad-fydd4fadyfdfd"]
      #
      # @return [Array<String>] IDs for all available compute instances
      def compute_list_ids
        # TODO: make it more efficient!
        compute_list.to_a.collect { |c| c.id }
      end

      # Gets all compute instances, instances must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
      # Returned collection must contain Occi::Infrastructure::Compute instances
      # wrapped in Occi::Core::Resources.
      #
      # @example
      #    computes = compute_list #=> #<Occi::Core::Resources>
      #    computes.first #=> #<Occi::Infrastructure::Compute>
      #
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    computes = compute_list(mixins) #=> #<Occi::Core::Resources>
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [Occi::Core::Resources] a collection of compute instances
      def compute_list(mixins = nil)
        compute = Occi::Core::Resources.new
        backend_compute_pool = ::OpenNebula::VirtualMachinePool.new(@client)
        rc = backend_compute_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        backend_compute_pool.each do |backend_compute|
          compute << compute_parse_backend_obj(backend_compute)
        end

        compute
      end

      # Gets a specific compute instance as Occi::Infrastructure::Compute.
      # ID given as an argument must match the occi.core.id attribute inside
      # the returned Occi::Infrastructure::Compute instance, however it is possible
      # to implement internal mapping to a platform-specific identifier.
      #
      # @example
      #    compute = compute_get('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<Occi::Infrastructure::Compute>
      #
      # @param compute_id [String] OCCI identifier of the requested compute instance
      # @return [Occi::Infrastructure::Compute, nil] a compute instance or `nil`
      def compute_get(compute_id)
        # TODO: make it more efficient!
        compute_list.to_a.select { |c| c.id == compute_id }.first
      end

      # Instantiates a new compute instance from Occi::Infrastructure::Compute.
      # ID given in the occi.core.id attribute is optional and can be changed
      # inside this method. Final occi.core.id must be returned as a String.
      # If the requested instance cannot be created, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute = Occi::Infrastructure::Compute.new
      #    compute_id = compute_create(compute)
      #        #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
      #
      # @param compute [Occi::Infrastructure::Compute] compute instance containing necessary attributes
      # @return [String] final identifier of the new compute instance
      def compute_create(compute)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Deletes all compute instances, instances to be deleted must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
      # If the requested instances cannot be deleted, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute_delete_all #=> true
      #
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    compute_delete_all(mixins)  #=> true
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [true, false] result of the operation
      def compute_delete_all(mixins = nil)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Deletes a specific compute instance, instance to be deleted is
      # specified by an ID, this ID must match the occi.core.id attribute
      # of the deleted instance.
      # If the requested instance cannot be deleted, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute_delete("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param compute_id [String] an identifier of a compute instance to be deleted
      # @return [true, false] result of the operation
      def compute_delete(compute_id)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Updates an existing compute instance, instance to be updated is specified
      # using the occi.core.id attribute of the instance passed as an argument.
      # If the requested instance cannot be updated, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute = Occi::Infrastructure::Compute.new
      #    compute_update(compute) #=> true
      #
      # @param compute [Occi::Infrastructure::Compute] instance containing updated information
      # @return [true, false] result of the operation
      def compute_update(compute)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Attaches a network to an existing compute instance, compute instance and network
      # instance in question are identified by occi.core.{source, target} attributes.
      # If the requested instance cannot be linked, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    networkinterface = Occi::Infrastructure::Networkinterface.new
      #    compute_attach_network(networkinterface) #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
      #
      # @param networkinterface [Occi::Infrastructure::Networkinterface] NI instance containing necessary attributes
      # @return [String] final identifier of the new network interface
      def compute_attach_network(networkinterface)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Attaches a storage to an existing compute instance, compute instance and storage
      # instance in question are identified by occi.core.{source, target} attributes.
      # If the requested instance cannot be linked, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    storagelink = Occi::Infrastructure::Storagelink.new
      #    compute_attach_storage(storagelink) #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
      #
      # @param storagelink [Occi::Infrastructure::Storagelink] SL instance containing necessary attributes
      # @return [String] final identifier of the new storage link
      def compute_attach_storage(storagelink)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Dettaches a network from an existing compute instance, the compute instance in question
      # must be identifiable using the networkinterface ID passed as an argument.
      # If the requested link instance cannot be dettached, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute_dettach_network("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param networkinterface_id [String] network interface identifier
      # @return [true, false] result of the operation
      def compute_dettach_network(networkinterface_id)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Dettaches a storage from an existing compute instance, the compute instance in question
      # must be identifiable using the storagelink ID passed as an argument.
      # If the requested link instance cannot be dettached, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute_dettach_storage("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param storagelink_id [String] storage link identifier
      # @return [true, false] result of the operation
      def compute_dettach_storage(storagelink_id)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Triggers an action on all existing compute instance, instances must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance,
      # action is identified by the action.term attribute of the action instance passed as an argument.
      # If the requested action cannot be triggered, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    action_instance = Occi::Core::ActionInstance.new
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    compute_trigger_action_on_all(action_instance, mixin) #=> true
      #
      # @param action_instance [Occi::Core::ActionInstance] action to be triggered
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [true, false] result of the operation
      def compute_trigger_action_on_all(action_instance, mixins = nil)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Triggers an action on an existing compute instance, the compute instance in question
      # is identified by a compute instance ID, action is identified by the action.term attribute
      # of the action instance passed as an argument.
      # If the requested action cannot be triggered, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    action_instance = Occi::Core::ActionInstance.new
      #    compute_trigger_action("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf", action_instance)
      #      #=> true
      #
      # @param compute_id [String] compute instance identifier
      # @param action_instance [Occi::Core::ActionInstance] action to be triggered
      # @return [true, false] result of the operation
      def compute_trigger_action(compute_id, action_instance)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      private

      def compute_parse_backend_obj(backend_compute)
        compute = Occi::Infrastructure::Compute.new

        # include some basic mixins
        compute.mixins << 'http://opennebula.org/occi/infrastructure#compute'

        # include mixins stored in ON's VM template
        unless backend_compute['USER_TEMPLATE/OCCI_COMPUTE_MIXINS'].blank?
          backend_compute_mixins = JSON.parse(backend_compute['USER_TEMPLATE/OCCI_COMPUTE_MIXINS'])
          backend_compute_mixins.each do |mixin|
            compute.mixins << mixin unless mixin.blank?
          end
        end

        compute.id    = backend_compute['ID']
        compute.title = backend_compute['NAME'] if backend_compute['NAME']
        compute.summary = backend_compute['USER_TEMPLATE/DESCRIPTION'] if backend_compute['USER_TEMPLATE/DESCRIPTION']

        compute.cores = (backend_compute['TEMPLATE/VCPU'] || "1").to_i
        compute.memory = backend_compute['TEMPLATE/MEMORY'].to_f/1000 if backend_compute['TEMPLATE/MEMORY']

        compute.architecture = "x64" if backend_compute['TEMPLATE/OS/ARCH'] == "x86_64"
        compute.architecture = "x86" if backend_compute['TEMPLATE/OS/ARCH'] == "i686"

        compute.attributes['org.opennebula.compute.cpu'] = backend_compute['TEMPLATE/CPU'].to_f if backend_compute['TEMPLATE/CPU']
        compute.attributes['org.opennebula.compute.kernel'] = backend_compute['TEMPLATE/OS/KERNEL'] if backend_compute['TEMPLATE/OS/KERNEL']
        compute.attributes['org.opennebula.compute.initrd'] = backend_compute['TEMPLATE/OS/INITRD'] if backend_compute['TEMPLATE/OS/INITRD']
        compute.attributes['org.opennebula.compute.root'] = backend_compute['TEMPLATE/OS/ROOT'] if backend_compute['TEMPLATE/OS/ROOT']
        compute.attributes['org.opennebula.compute.kernel_cmd'] = backend_compute['TEMPLATE/OS/KERNEL_CMD'] if backend_compute['TEMPLATE/OS/KERNEL_CMD']
        compute.attributes['org.opennebula.compute.bootloader'] = backend_compute['TEMPLATE/OS/BOOTLOADER'] if backend_compute['TEMPLATE/OS/BOOTLOADER']
        compute.attributes['org.opennebula.compute.boot'] = backend_compute['TEMPLATE/OS/BOOT'] if backend_compute['TEMPLATE/OS/BOOT']

        result = compute_parse_set_state(backend_compute)
        compute.state = result.state
        compute.actions = result.actions

        result = compute_parse_links(backend_compute, compute)
        result.each { |link| compute.links << link }

        compute
      end

      def compute_parse_set_state(backend_compute)
        result = Hashie::Mash.new

        # TODO: more states?
        # In ON 4.4:
        #    VM_STATE=%w{INIT PENDING HOLD ACTIVE STOPPED SUSPENDED DONE FAILED
        #       POWEROFF UNDEPLOYED}
        #
        case backend_compute.state_str
        when "ACTIVE"
          result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart http://schemas.ogf.org/occi/infrastructure/compute/action#suspend|
        when "FAILED"
          result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#restart|
        when "STOPPED", "SUSPENDED", "POWEROFF"
          result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
        else
          result.actions = []
        end

        result.state ||= backend_compute.state_str.downcase

        result
      end

      def compute_parse_links(backend_compute, compute)
        result = []

        result << compute_parse_links_storage(backend_compute, compute)
        result << compute_parse_links_network(backend_compute, compute)
        result.flatten!

        result
      end

      def compute_parse_links_storage(backend_compute, compute)
        result_storage_links = []

        backend_compute.each('TEMPLATE/DISK') do |disk|
          id = "compute_#{backend_compute['ID']}_disk_#{disk['DISK_ID']}"

          link = Occi::Infrastructure::Storagelink.new
          link.id = id
          link.state = "active"

          target = storage_get(disk['IMAGE_ID']) if disk['IMAGE_ID']
          unless target
            target = Occi::Infrastructure::Storage.new
            target.id = "#{STORAGE_GENERATED_PREFIX}#{id}"
            target.title = "Generated target for an on-the-fly created non-persistent disk"
          end

          link.target = target
          link.rel = target.kind
          link.title = target.title if target.title
          link.source = compute

          link.mixins << 'http://opennebula.org/occi/infrastructure#storagelink'

          unless backend_compute['USER_TEMPLATE/OCCI_STORAGELINK_MIXINS'].blank?
            backend_mixins = JSON.parse(backend_compute['USER_TEMPLATE/OCCI_STORAGELINK_MIXINS'])
            backend_mixins[id].each do |mixin|
              link.mixins << mixin unless mixin.blank?
            end if backend_mixins[id]
          end

          link.deviceid = disk['TARGET'] if disk['TARGET']
          link.attributes['org.opennebula.storagelink.bus'] = disk['BUS'] if disk['BUS']
          link.attributes['org.opennebula.storagelink.driver'] = disk['DRIVER'] if disk['TARGET']

          result_storage_links << link
        end

        result_storage_links
      end

      def compute_parse_links_network(backend_compute, compute)
        result_network_links = []

        backend_compute.each('TEMPLATE/NIC') do |nic|
          id = "compute_#{backend_compute['ID']}_nic_#{nic['NIC_ID']}"

          link = Occi::Infrastructure::Networkinterface.new
          link.id = id
          link.state = "active"

          target = network_get(nic['NETWORK_ID']) if nic['NETWORK_ID']
          unless target
            target = Occi::Infrastructure::Network.new
            target.id = "#{NETWORK_GENERATED_PREFIX}#{id}"
            target.title = "Generated target for a non-existent network (probably removed)"
          end

          link.target = target
          link.rel = target.kind
          link.title = target.title if target.title
          link.source = compute

          link.mixins << 'http://schemas.ogf.org/occi/infrastructure/networkinterface#ipnetworkinterface'
          link.mixins << 'http://opennebula.org/occi/infrastructure#networkinterface'

          unless backend_compute['USER_TEMPLATE/OCCI_NETWORKINTERFACE_MIXINS'].blank?
            backend_mixins = JSON.parse(backend_compute['USER_TEMPLATE/OCCI_NETWORKINTERFACE_MIXINS'])
            backend_mixins[id].each do |mixin|
              link.mixins << mixin unless mixin.blank?
            end if backend_mixins[id]
          end

          link.address = nic['IP'] if nic['IP']
          link.mac = nic['MAC'] if nic['MAC']
          link.interface = "eth#{nic['NIC_ID']}"
          link.model = nic['MODEL'] if nic['MODEL']

          link.attributes['org.opennebula.networkinterface.bridge'] = nic['BRIDGE'] if nic['BRIDGE']
          link.attributes['org.opennebula.networkinterface.white_ports_tcp'] = nic['WHITE_PORTS_TCP'] if nic['WHITE_PORTS_TCP']
          link.attributes['org.opennebula.networkinterface.black_ports_tcp'] = nic['BLACK_PORTS_TCP'] if nic['BLACK_PORTS_TCP']
          link.attributes['org.opennebula.networkinterface.white_ports_udp'] = nic['WHITE_PORTS_UDP'] if nic['WHITE_PORTS_UDP']
          link.attributes['org.opennebula.networkinterface.black_ports_udp'] = nic['BLACK_PORTS_UDP'] if nic['BLACK_PORTS_UDP ']
          link.attributes['org.opennebula.networkinterface.icmp'] = nic['ICMP'] if nic['ICMP ']

          result_network_links << link
        end

        result_network_links
      end

    end
  end
end