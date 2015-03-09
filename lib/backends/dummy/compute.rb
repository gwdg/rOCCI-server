module Backends
  module Dummy
    module Compute
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
        ###
        # Every Occi::Infrastructure::Compute instance contains an attribute
        # called 'occi.core.id' aliased as the #id method. This must be unique
        # within the running rOCCI-server instance. This attribute is generated
        # as a UUID by default for every new instance.
        #
        # compute = Occi::Infrastructure::Compute.new
        # compute.id  #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
        # compute.id == compute.attributes['occi.core.id'] #=> true
        # compute.id = 'my_unique_id'
        # compute.location #=> "/compute/my_unique_id"
        ###
        compute_list(mixins).to_a.map { |c| c.id }
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
        ###
        # To fill in the required collection, create
        # instances of the Occi::Infrastructure::Compute class and place
        # them in a fresh Occi::Core::Resources instance. You should set
        # the following attributes on each Occi::Infrastructure::Compute
        # instance:
        #
        # compute = Occi::Infrastructure::Compute.new
        # compute.id = 'my_unique_id'         # this MUST NOT change during the lifetime of the given instance
        # compute.title = 'my_instance_name'
        # compute.summary = 'my_instance_description'
        # compute.architecture = 'x86'
        # compute.cores = 10                  # number of VCPUs
        # compute.memory = 1.7                # in GBs
        # compute.hostname = 'compute1.example.org'
        # compute.state = 'active'            # 'inactive', 'suspended' or 'error'
        #
        # Once the instance is ready, add it to the collection:
        #
        # resources = Occi::Core::Resources.new
        # resources << compute
        #
        # If your backend supports mixins, such as `os_tpl` or `resource_tpl`, and
        # the given instance was launched with one, you should associate them with
        # the instance:
        #
        # mixin = Occi::Core::Mixin.new(scheme, term)
        # compute.mixins << mixin
        #
        # Once the mixin is associated, you can set attributes it adds to the compute
        # instance.
        ###
        if mixins.blank?
          read_compute_fixtures
        else
          filtered_computes = read_compute_fixtures.to_a.select { |c| (c.mixins & mixins).any? }
          Occi::Core::Resources.new filtered_computes
        end
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
        ###
        # See #compute_list for details on how to create Occi::Infrastructure::Compute instances.
        # Here you simply select a specific instance with a matching ID.
        # Since IDs must be unique, you should always return at most one instance.
        ###
        found = compute_list.to_a.select { |c| c.id == compute_id }.first
        fail Backends::Errors::ResourceNotFoundError, "Instance with ID #{compute_id} does not exist!" unless found

        found
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
        ###
        # As an argument, you will receive a prepared Occi::Infrastructure::Compute
        # instance containing all available data. The underlying cloud platform
        # must create an instance based on this information. Here you should also
        # generate a unique ID (the process must be repeatable or reversible) or
        # "remember" the ID already generated by rOCCI. This is important for later
        # ID-based look-up of running instances. If you need to use cache or a permanent
        # storage, you have to use tools out of scope of the rOCCI-server (a database, memcache, etc.).
        #
        # Given Occi::Infrastructure::Compute instance is frozen and unmodifiable!
        ###
        fail Backends::Errors::IdentifierConflictError, "Instance with ID #{compute.id} already exists!" if compute_list_ids.include?(compute.id)

        compute.state = 'active'
        updated = read_compute_fixtures << compute
        save_compute_fixtures(updated)

        compute.id
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
        ###
        # Simply destroy all running instances of the current user.
        # Filtration mechanism works the same way as in #compute_list.
        ###
        if mixins.blank?
          drop_compute_fixtures
          read_compute_fixtures.empty?
        else
          old_count = read_compute_fixtures.count
          updated = read_compute_fixtures.delete_if { |c| (c.mixins & mixins).any? }
          save_compute_fixtures(updated)
          old_count != read_compute_fixtures.count
        end
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
        ###
        # Again, operation on a single resource instance. The opposite
        # of #compute_create.
        ###
        fail Backends::Errors::ResourceNotFoundError, "Instance with ID #{compute_id} does not exist!" unless compute_list_ids.include?(compute_id)

        updated = read_compute_fixtures.delete_if { |c| c.id == compute_id }
        save_compute_fixtures(updated)

        begin
          compute_get(compute_id)
          false
        rescue Backends::Errors::ResourceNotFoundError
          true
        end
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
        ###
        # To update an existing resource, you should read attributes
        # from the given Occi::Infrastructure::Compute instance and
        # change the appropriate instance in the underlying cloud
        # platform. Update can be partial or full. This has to be
        # decided internally based on attributes set in the given
        # Occi::Infrastructure::Compute instance.
        ###
        fail Backends::Errors::ResourceNotFoundError, "Instance with ID #{compute.id} does not exist!" unless compute_list_ids.include?(compute.id)

        compute_delete(compute.id)
        updated = read_compute_fixtures << compute
        save_compute_fixtures(updated)
        compute_get(compute.id) == compute
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
        ###
        # To attach a networkinterface, you should read attributes from
        # the given link instance. Two important attributes are:
        #
        #    'occi.core.source' -- location of a compute instance
        #    'occi.core.target' -- location of a network instance
        #
        # The last part of both URIs (after the last slash) corresponds
        # with compute and network instance IDs. You can use `compute_get(id)`
        # or `network_get(id)` to retrieve them.
        # How you attach the given network to the given compute instance is
        # completely up to you, but you have to:
        #
        #    1.) return a unique identifier which can be used to reference
        #        this particular link in the future (i.e. it must not change!)
        #    2.) include information about this link in all subsequent
        #        instances of Occi::Infrastructure::Compute with a location matching
        #        'occi.core.source'
        #
        # In case a link cannot be created for any reason, you must raise
        # an error, @see Backends::Errors.
        ###
        compute = compute_get(networkinterface.attributes['occi.core.source'].split('/').last)
        network = network_get(networkinterface.attributes['occi.core.target'].split('/').last)

        fail Backends::Errors::ResourceNotFoundError, 'Given compute instance does not exist!' unless compute
        fail Backends::Errors::ResourceNotFoundError, 'Given network instance does not exist!' unless network

        compute.links << networkinterface

        compute_delete(compute.id)
        updated = read_compute_fixtures << compute
        save_compute_fixtures(updated)

        networkinterface.id
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
        ###
        # To attach a storagelink, you should read attributes from
        # the given link instance. Two important attributes are:
        #
        #    'occi.core.source' -- location of a compute instance
        #    'occi.core.target' -- location of a network instance
        #
        # The last part of both URIs (after the last slash) corresponds
        # with compute and storage instance IDs. You can use `compute_get(id)`
        # or `storage_get(id)` to retrieve them.
        # How you attach the given storage to the given compute instance is
        # completely up to you, but you have to:
        #
        #    1.) return a unique identifier which can be used to reference
        #        this particular link in the future (i.e. it must not change!)
        #    2.) include information about this link in all subsequent
        #        instances of Occi::Infrastructure::Compute with a location matching
        #        'occi.core.source'
        #
        # In case a link cannot be created for any reason, you must raise
        # an error, @see Backends::Errors.
        ###
        compute = compute_get(storagelink.attributes['occi.core.source'].split('/').last)
        storage = storage_get(storagelink.attributes['occi.core.target'].split('/').last)

        fail Backends::Errors::ResourceNotFoundError, 'Given compute instance does not exist!' unless compute
        fail Backends::Errors::ResourceNotFoundError, 'Given storage instance does not exist!' unless storage

        compute.links << storagelink

        compute_delete(compute.id)
        updated = read_compute_fixtures << compute
        save_compute_fixtures(updated)

        storagelink.id
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
        ###
        # Every networkinterface link is uniquely identified by its ID. It must
        # be possible to look up a link using only this ID.
        # To detach a link, identify the compute instance in question, identify
        # the correct interface, disconnect the interface and remove all traces
        # of the link. It must not appear in any subsequent instances of
        # Occi::Infrastructure::Compute.
        # In case a link cannot be detached for any reason, you must raise
        # an error, @see Backends::Errors.
        ###
        compute_list.to_a.each do |compute|
          next if compute.links.blank?
          old_size = compute.links.size

          compute.links.delete_if do |l|
            l.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#networkinterface' \
                 && \
            l.id == networkinterface_id
          end

          unless old_size == compute.links.size
            compute_delete(compute.id)
            updated = read_compute_fixtures << compute
            save_compute_fixtures(updated)
            break
          end
        end

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
        ###
        # Every storagelink link is uniquely identified by its ID. It must
        # be possible to look up a link using only this ID.
        # To detach a link, identify the compute instance in question, identify
        # the correct device, disconnect the device and remove all traces
        # of the link. It must not appear in any subsequent instances of
        # Occi::Infrastructure::Compute.
        # In case a link cannot be detached for any reason, you must raise
        # an error, @see Backends::Errors.
        ###
        compute_list.to_a.each do |compute|
          next if compute.links.blank?
          old_size = compute.links.size

          compute.links.delete_if do |l|
            l.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#storagelink' \
                 && \
            l.id == storagelink_id
          end

          unless old_size == compute.links.size
            compute_delete(compute.id)
            updated = read_compute_fixtures << compute
            save_compute_fixtures(updated)
            break
          end
        end

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
        ###
        # See descriptions in compute_{attach,detach}_network for details. This
        # method is non-destructive, it simply retrieves information about a link
        # identified by 'networkinterface_id'.
        ###
        found = nil
        compute_list.to_a.each do |compute|
          next if compute.links.blank?

          found = compute.links.to_a.select do |l|
            l.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#networkinterface' \
                 && \
            l.id == networkinterface_id
          end

          break unless found.blank?
        end

        fail Backends::Errors::ResourceNotFoundError, 'Given link instance does not exist!' if found.blank?

        found.first
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
        ###
        # See descriptions in compute_{attach,detach}_storage for details. This
        # method is non-destructive, it simply retrieves information about a link
        # identified by 'storagelink_id'.
        ###
        found = nil
        compute_list.to_a.each do |compute|
          next if compute.links.blank?

          found = compute.links.to_a.select do |l|
            l.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#storagelink' \
                 && \
            l.id == storagelink_id
          end

          break unless found.blank?
        end

        fail Backends::Errors::ResourceNotFoundError, 'Given link instance does not exist!' if found.blank?

        found.first
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
          state = 'inactive'
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#start'
          state = 'active'
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#restart'
          state = 'active'
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#suspend'
          state = 'suspended'
        else
          fail Backends::Errors::ActionNotImplementedError,
               "Action #{action_instance.action.type_identifier.inspect} is not implemented!"
        end

        # get existing compute instance and set a new state
        compute = compute_get(compute_id)
        compute.state = state

        # clean-up and save the new collection
        compute_delete(compute.id)
        updated = read_compute_fixtures << compute
        save_compute_fixtures(updated)

        true
      end
    end
  end
end
