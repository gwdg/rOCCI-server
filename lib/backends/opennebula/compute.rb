module Backends
  module Opennebula
    module Compute
      COMPUTE_NINTF_REGEXP = /compute_(?<compute_id>\d+)_nic_(?<compute_nic_id>\d+)/
      COMPUTE_SLINK_REGEXP = /compute_(?<compute_id>\d+)_disk_(?<compute_disk_id>\d+)/

      # Gets all compute instance IDs, no details, no duplicates. Returned
      # identifiers must correspond to those found in the occi.core.id
      # attribute of Occi::Infrastructure::Compute instances.
      #
      # @example
      #    compute_list_ids #=> []
      #    compute_list_ids #=> ["65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf",
      #                             "ggf4f65adfadf-adgg4ad-daggad-fydd4fadyfdfd"]
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [Array<String>] IDs for all available compute instances
      def compute_list_ids(mixins = nil)
        # TODO: impl filtering with mixins
        backend_compute_pool = ::OpenNebula::VirtualMachinePool.new(@client)
        rc = backend_compute_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        compute = []
        backend_compute_pool.each do |backend_compute|
          compute << backend_compute['ID']
        end

        compute
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
        # TODO: impl filtering with mixins
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
        virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(compute_id), @client)
        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        fail Backends::Errors::ResourceNotFoundError, "Instance with ID #{compute_id} does not exist!" if virtual_machine.state_str == 'DONE'
        compute_parse_backend_obj(virtual_machine)
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
        compute_id = compute.id

        os_tpl_mixins = compute.mixins.get_related_to(Occi::Infrastructure::OsTpl.mixin.type_identifier)
        if !os_tpl_mixins.empty?
          compute_id = compute_create_with_os_tpl(compute)
        elsif !compute.links.empty?
          compute_id = compute_create_with_links(compute)
        else
          fail Backends::Errors::ResourceNotValidError,
               "Given instance contains neither an os_tpl " \
               "mixin or links necessary to create a virtual machine!"
        end

        compute_id
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
        # TODO: impl filtering with mixins
        backend_compute_pool = ::OpenNebula::VirtualMachinePool.new(@client)
        rc = backend_compute_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        backend_compute_pool.each do |backend_compute|
          if backend_compute.lcm_state_str == 'RUNNING'
            rc = backend_compute.shutdown
          else
            rc = backend_compute.delete
          end

          check_retval(rc, Backends::Errors::ResourceActionError)
        end

        true
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
        virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(compute_id), @client)
        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        if virtual_machine.lcm_state_str == 'RUNNING'
          rc = virtual_machine.shutdown
        else
          rc = virtual_machine.delete
        end

        check_retval(rc, Backends::Errors::ResourceActionError)

        true
      end

      # Partially updates an existing compute instance, instance to be updated
      # is specified by compute_id.
      # If the requested instance cannot be updated, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    attributes = Occi::Core::Attributes.new
      #    mixins = Occi::Core::Mixins.new
      #    links = Occi::Core::Links.new
      #    compute_partial_update(compute_id, attributes, mixins, links) #=> true
      #
      # @param compute_id [String] unique identifier of a compute instance to be updated
      # @param attributes [Occi::Core::Attributes] a collection of attributes to be updated
      # @param mixins [Occi::Core::Mixins] a collection of mixins to be added
      # @param links [Occi::Core::Links] a collection of links to be added
      # @return [true, false] result of the operation
      def compute_partial_update(compute_id, attributes = nil, mixins = nil, links = nil)
        # TODO: impl
        fail Backends::Errors::MethodNotImplementedError, 'Partial updates are currently not supported!'
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
        virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(compute.id), @client)
        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        fail Backends::Errors::ResourceStateError, 'Given compute instance is not powered off!' unless virtual_machine.state_str == 'POWEROFF'

        resize_template = ''
        resize_template << "VCPU = #{compute.cores.to_i}" if compute.cores
        resize_template << "CPU = #{compute.speed.to_f * (compute.cores || virtual_machine['TEMPLATE/VCPU']).to_i}" if compute.speed
        resize_template << "MEMORY = #{(compute.memory.to_f * 1024).to_i}" if compute.memory

        return false if resize_template.blank?

        rc = virtual_machine.resize(resize_template, true)
        check_retval(rc, Backends::Errors::ResourceActionError)

        true
      end

      # Attaches a network to an existing compute instance, compute instance and network
      # instance in question are identified by occi.core.source, occi.core.target attributes.
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
        compute_id = networkinterface.attributes['occi.core.source'].split('/').last

        virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(compute_id), @client)
        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        fail Backends::Errors::ResourceStateError, 'Given compute instance is not running!' unless virtual_machine.lcm_state_str == 'RUNNING'

        template_location = File.join(@options.templates_dir, 'compute_nic.erb')
        template = Erubis::Eruby.new(File.read(template_location)).evaluate(networkinterface: networkinterface)

        rc = virtual_machine.nic_attach(template)
        check_retval(rc, Backends::Errors::ResourceActionError)

        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        "compute_#{virtual_machine['ID']}_nic_#{virtual_machine['TEMPLATE/NIC[last()]/NIC_ID']}"
      end

      # Attaches a storage to an existing compute instance, compute instance and storage
      # instance in question are identified by occi.core.source, occi.core.target attributes.
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
        compute_id = storagelink.attributes['occi.core.source'].split('/').last

        virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(compute_id), @client)
        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        fail Backends::Errors::ResourceStateError, 'Given compute instance is not running!' unless virtual_machine.lcm_state_str == 'RUNNING'

        template_location = File.join(@options.templates_dir, 'compute_disk.erb')
        template = Erubis::Eruby.new(File.read(template_location)).evaluate(storagelink: storagelink)

        rc = virtual_machine.disk_attach(template)
        check_retval(rc, Backends::Errors::ResourceActionError)

        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        "compute_#{virtual_machine['ID']}_disk_#{virtual_machine['TEMPLATE/DISK[last()]/DISK_ID']}"
      end

      # Detaches a network from an existing compute instance, the compute instance in question
      # must be identifiable using the networkinterface ID passed as an argument.
      # If the requested link instance cannot be detached, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute_detach_network("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param networkinterface_id [String] network interface identifier
      # @return [true, false] result of the operation
      def compute_detach_network(networkinterface_id)
        matched = COMPUTE_NINTF_REGEXP.match(networkinterface_id)
        fail Backends::Errors::IdentifierNotValidError, 'ID of the given networkinterface is not valid!' unless matched

        virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(matched[:compute_id]), @client)
        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        fail Backends::Errors::ResourceStateError, 'Given compute instance is not running!' unless virtual_machine.lcm_state_str == 'RUNNING'

        rc = virtual_machine.nic_detach(matched[:compute_nic_id].to_i)
        check_retval(rc, Backends::Errors::ResourceActionError)

        true
      end

      # Detaches a storage from an existing compute instance, the compute instance in question
      # must be identifiable using the storagelink ID passed as an argument.
      # If the requested link instance cannot be detached, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute_detach_storage("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param storagelink_id [String] storage link identifier
      # @return [true, false] result of the operation
      def compute_detach_storage(storagelink_id)
        matched = COMPUTE_SLINK_REGEXP.match(storagelink_id)
        fail Backends::Errors::IdentifierNotValidError, 'ID of the given storagelink is not valid!' unless matched

        virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(matched[:compute_id]), @client)
        rc = virtual_machine.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        fail Backends::Errors::ResourceStateError, 'Given compute instance is not running!' unless virtual_machine.lcm_state_str == 'RUNNING'

        rc = virtual_machine.disk_detach(matched[:compute_disk_id].to_i)
        check_retval(rc, Backends::Errors::ResourceActionError)

        true
      end

      # Gets a network from an existing compute instance, the compute instance in question
      # must be identifiable using the networkinterface ID passed as an argument.
      # If the requested link instance cannot be found, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute_get_network("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf")
      #        #=> #<Occi::Infrastructure::Networkinterface>
      #
      # @param networkinterface_id [String] network interface identifier
      # @return [Occi::Infrastructure::Networkinterface] instance of the found networkinterface
      def compute_get_network(networkinterface_id)
        matched = COMPUTE_NINTF_REGEXP.match(networkinterface_id)
        fail Backends::Errors::IdentifierNotValidError, 'ID of the given networkinterface is not valid!' unless matched

        intf = compute_get(matched[:compute_id]).links.to_a.select { |l| l.id == networkinterface_id }
        fail Backends::Errors::ResourceNotFoundError, 'Networkinterface with the given ID does not exist!' if intf.blank?

        intf.first
      end

      # Gets a storage from an existing compute instance, the compute instance in question
      # must be identifiable using the storagelink ID passed as an argument.
      # If the requested link instance cannot be detached, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute_get_storage("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf")
      #        #=> #<Occi::Infrastructure::Storagelink>
      #
      # @param storagelink_id [String] storage link identifier
      # @return [Occi::Infrastructure::Storagelink] instance of the found storagelink
      def compute_get_storage(storagelink_id)
        matched = COMPUTE_SLINK_REGEXP.match(storagelink_id)
        fail Backends::Errors::IdentifierNotValidError, 'ID of the given storagelink is not valid!' unless matched

        link = compute_get(matched[:compute_id]).links.to_a.select { |l| l.id == storagelink_id }
        fail Backends::Errors::ResourceNotFoundError, 'Storagelink with the given ID does not exist!' if link.blank?

        link.first
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
        compute_list_ids(mixins).each { |cmpt| compute_trigger_action(cmpt, action_instance) }
        true
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
        case action_instance.action.type_identifier
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#stop'
          compute_trigger_action_stop(compute_id, action_instance.attributes)
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#start'
          compute_trigger_action_start(compute_id, action_instance.attributes)
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#restart'
          compute_trigger_action_restart(compute_id, action_instance.attributes)
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#suspend'
          compute_trigger_action_suspend(compute_id, action_instance.attributes)
        else
          fail Backends::Errors::ActionNotImplementedError,
               "Action #{action_instance.action.type_identifier.inspect} is not implemented!"
        end

        true
      end

      private

      # Load methods called from compute_list/compute_get
      include Backends::Opennebula::Helpers::ComputeParseHelper

      # Load methods called from compute_create
      include Backends::Opennebula::Helpers::ComputeCreateHelper

      # Load methods called from compute_trigger_action*
      include Backends::Opennebula::Helpers::ComputeActionHelper
    end
  end
end
