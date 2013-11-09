module BackendApi
  module Compute

    # Gets all compute instances in an Occi::Collection, instances must be filtered
    # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
    # Returned collection must contain Occi::Infrastructure::Compute instances
    # wrapped in Occi::Core::Resources.
    #
    # @example
    #    collection = compute_get_all #=> #<Occi::Collection>
    #    collection.resources  #=> #<Occi::Core::Resources>
    #    collection.resources.first #=> #<Occi::Infrastructure::Compute>
    #
    #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
    #    collection = compute_get_all(mixins) #=> #<Occi::Collection>
    #
    # @param mixins [Occi::Core::Mixins] a filter containing mixins
    # @return [Occi::Collection] a collection of compute instances
    def compute_get_all(mixins = nil)
      mixins = mixins.deep_freeze if mixins
      collection = @backend_instance.compute_get_all(mixins) || Occi::Collection.new
      collection.deep_freeze
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
      raise ArgumentError, '\'compute_id\' is a mandatory argument' if compute_id.blank?
      compute = @backend_instance.compute_get(compute_id)
      compute.deep_freeze if compute
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
      raise ArgumentError, '\'compute\' is a mandatory argument' if compute.blank?
      @backend_instance.compute_create(compute.deep_freeze)
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
      mixins = mixins.deep_freeze if mixins
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
      raise ArgumentError, '\'compute_id\' is a mandatory argument' if compute_id.blank?
      @backend_instance.compute_delete(compute_id)
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
      raise ArgumentError, '\'compute\' is a mandatory argument' if compute.blank?
      @backend_instance.compute_update(compute.deep_freeze)
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
      raise ArgumentError, '\'networkinterface\' is a mandatory argument' if networkinterface.blank?
      @backend_instance.compute_attach_network(networkinterface.deep_freeze)
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
      raise ArgumentError, '\'storagelink\' is a mandatory argument' if storagelink.blank?
      @backend_instance.compute_attach_storage(storagelink.deep_freeze)
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
      raise ArgumentError, '\'networkinterface_id\' is a mandatory argument' if networkinterface_id.blank?
      @backend_instance.compute_dettach_network(networkinterface_id)
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
      raise ArgumentError, '\'storagelink_id\' is a mandatory argument' if storagelink_id.blank?
      @backend_instance.compute_dettach_storage(storagelink_id)
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
      raise ArgumentError, '\'action_instance\' is a mandatory argument' if action_instance.blank?
      mixins = mixins.deep_freeze if mixins
      @backend_instance.compute_trigger_action_on_all(action_instance.deep_freeze, mixins)
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
      raise ArgumentError, '\'compute_id\' is a mandatory argument' if compute_id.blank?
      raise ArgumentError, '\'action_instance\' is a mandatory argument' if action_instance.blank?
      @backend_instance.compute_trigger_action(compute_id, action_instance.deep_freeze)
    end

  end
end