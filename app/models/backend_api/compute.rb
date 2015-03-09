module BackendApi
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
      mixins = deep_clone(mixins) if mixins
      @backend_instance.compute_list_ids(mixins) || []
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
      mixins = deep_clone(mixins) if mixins
      @backend_instance.compute_list(mixins) || Occi::Core::Resources.new
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
      fail Errors::ArgumentError, '\'compute_id\' is a mandatory argument' if compute_id.blank?
      @backend_instance.compute_get(compute_id)
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
      fail Errors::ArgumentError, '\'compute\' is a mandatory argument' if compute.blank?
      fail Errors::ArgumentTypeMismatchError, 'Action requires a compute instance!' unless compute.kind_of? Occi::Infrastructure::Compute
      @backend_instance.compute_create(deep_clone(compute))
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
      mixins = deep_clone(mixins) if mixins
      @backend_instance.compute_delete_all(mixins)
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
      fail Errors::ArgumentError, '\'compute_id\' is a mandatory argument' if compute_id.blank?
      @backend_instance.compute_delete(compute_id)
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
      fail Errors::ArgumentError, '\'compute_id\' is a mandatory argument' if compute_id.blank?
      attributes ||= Occi::Core::Attributes.new
      mixins ||= Occi::Core::Mixins.new
      links ||= Occi::Core::Links.new

      unless attributes.kind_of?(Occi::Core::Attributes) && mixins.kind_of?(Occi::Core::Mixins) && links.kind_of?(Occi::Core::Links)
        fail Errors::ArgumentTypeMismatchError, 'Action requires attributes, mixins or links to be updated!'
      end

      @backend_instance.compute_partial_update(compute_id, deep_clone(attributes), deep_clone(mixins), deep_clone(links))
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
      fail Errors::ArgumentError, '\'compute\' is a mandatory argument' if compute.blank?
      fail Errors::ArgumentTypeMismatchError, 'Action requires a compute instance!' unless compute.kind_of? Occi::Infrastructure::Compute
      @backend_instance.compute_update(deep_clone(compute))
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
      fail Errors::ArgumentError, '\'networkinterface\' is a mandatory argument' if networkinterface.blank?
      fail Errors::ArgumentTypeMismatchError, 'Action requires a link instance!' unless networkinterface.kind_of? Occi::Core::Link
      fail Errors::ArgumentTypeMismatchError, 'Action requires a networkinterface instance!' unless networkinterface.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#networkinterface'
      @backend_instance.compute_attach_network(deep_clone(networkinterface))
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
      fail Errors::ArgumentError, '\'storagelink\' is a mandatory argument' if storagelink.blank?
      fail Errors::ArgumentTypeMismatchError, 'Action requires a link instance!' unless storagelink.kind_of? Occi::Core::Link
      fail Errors::ArgumentTypeMismatchError, 'Action requires a storagelink instance!' unless storagelink.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#storagelink'
      @backend_instance.compute_attach_storage(deep_clone(storagelink))
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
      fail Errors::ArgumentError, '\'networkinterface_id\' is a mandatory argument' if networkinterface_id.blank?
      @backend_instance.compute_detach_network(networkinterface_id)
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
      fail Errors::ArgumentError, '\'storagelink_id\' is a mandatory argument' if storagelink_id.blank?
      @backend_instance.compute_detach_storage(storagelink_id)
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
      fail Errors::ArgumentError, '\'networkinterface_id\' is a mandatory argument' if networkinterface_id.blank?
      @backend_instance.compute_get_network(networkinterface_id)
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
      fail Errors::ArgumentError, '\'storagelink_id\' is a mandatory argument' if storagelink_id.blank?
      @backend_instance.compute_get_storage(storagelink_id)
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
      fail Errors::ArgumentError, '\'action_instance\' is a mandatory argument' if action_instance.blank?
      fail Errors::ArgumentTypeMismatchError, 'Action requires an action instance!' unless action_instance.kind_of? Occi::Core::ActionInstance
      mixins = deep_clone(mixins) if mixins
      @backend_instance.compute_trigger_action_on_all(deep_clone(action_instance), mixins)
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
      fail Errors::ArgumentError, '\'compute_id\' is a mandatory argument' if compute_id.blank?
      fail Errors::ArgumentError, '\'action_instance\' is a mandatory argument' if action_instance.blank?
      fail Errors::ArgumentTypeMismatchError, 'Action requires an action instance!' unless action_instance.kind_of? Occi::Core::ActionInstance
      @backend_instance.compute_trigger_action(compute_id, deep_clone(action_instance))
    end
  end
end
