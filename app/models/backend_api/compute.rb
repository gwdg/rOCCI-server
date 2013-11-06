module BackendApi
  module Compute

    # Get all compute resources (== instances) in an Occi::Collection.
    # Collection must contain Occi::Infrastructure::Compute instances
    # wrapped in Occi::Core::Resources.
    #
    # @example
    #    collection = compute_get_all #=> #<Occi::Collection>
    #    collection.resources  #=> #<Occi::Core::Resources>
    #    collection.resources.first #=> #<Occi::Infrastructure::Compute>
    #
    # @return [Occi::Collection] a collection of compute resources
    def compute_get_all
      collection = @backend_instance.compute_get_all || Occi::Collection.new
      collection.deep_freeze
    end

    # Get a specific compute resource (== instance) as Occi::Infrastructure::Compute.
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
      compute = @backend_instance.compute_get(compute_id)
      compute.deep_freeze if compute
    end

    # Instantiate a new compute resource from Occi::Infrastructure::Compute.
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
      @backend_instance.compute_create(compute.deep_freeze)
    end

    # @param compute_id [String]
    # @return [true, false]
    def compute_delete(compute_id)
      @backend_instance.compute_delete(compute_id)
    end

    # @param compute [Occi::Infrastructure::Compute]
    # @return [true, false]
    def compute_update(compute)
      @backend_instance.compute_update(compute.deep_freeze)
    end

    # @param networkinterface [Occi::Infrastructure::Networkinterface] NI instance containing necessary attributes
    # @return [String] final identifier of the new network interface
    def compute_attach_network(networkinterface)
      @backend_instance.compute_attach_network(networkinterface.deep_freeze)
    end

    # @param storagelink [Occi::Infrastructure::Storagelink] SL instance containing necessary attributes
    # @return [String] final identifier of the new storage link
    def compute_attach_storage(storagelink)
      @backend_instance.compute_attach_storage(storagelink.deep_freeze)
    end

    # @param networkinterface_id [String]
    # @return [true, false]
    def compute_dettach_network(networkinterface_id)
      @backend_instance.compute_dettach_network(networkinterface_id)
    end

    # @param storagelink_id [String]
    # @return [true, false]
    def compute_dettach_storage(storagelink_id)
      @backend_instance.compute_dettach_storage(storagelink_id)
    end

    # @param compute_id [String]
    # @param action_instance [Occi::Core::ActionInstance]
    # @return [true, false]
    def compute_trigger_action(compute_id, action_instance)
      @backend_instance.compute_trigger_action(compute_id, action_instance.deep_freeze)
    end

  end
end