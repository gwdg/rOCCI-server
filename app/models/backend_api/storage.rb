module BackendApi
  module Storage

    # Gets all storage instances in an Occi::Collection, instances must be filtered
    # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
    # Returned collection must contain Occi::Infrastructure::Storage instances
    # wrapped in Occi::Core::Resources.
    #
    # @example
    #    collection = storage_get_all #=> #<Occi::Collection>
    #    collection.resources  #=> #<Occi::Core::Resources>
    #    collection.resources.first #=> #<Occi::Infrastructure::Storage>
    #
    #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
    #    collection = storage_get_all(mixins) #=> #<Occi::Collection>
    #
    # @param mixins [Occi::Core::Mixins] a filter containing mixins
    # @return [Occi::Collection] a collection of storage instances
    def storage_get_all(mixins = nil)
      mixins = mixins.deep_freeze if mixins
      collection = @backend_instance.storage_get_all(mixins) || Occi::Collection.new
      collection.deep_freeze
    end

    # Gets a specific storage instance as Occi::Infrastructure::Storage.
    # ID given as an argument must match the occi.core.id attribute inside
    # the returned Occi::Infrastructure::Storage instance, however it is possible
    # to implement internal mapping to a platform-specific identifier.
    #
    # @example
    #    storage = storage_get('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
    #        #=> #<Occi::Infrastructure::Storage>
    #
    # @param storage_id [String] OCCI identifier of the requested storage instance
    # @return [Occi::Infrastructure::Storage, nil] a storage instance or `nil`
    def storage_get(storage_id)
      raise ArgumentError, '\'storage_id\' is a mandatory argument' if storage_id.blank?
      storage = @backend_instance.storage_get(storage_id)
      storage.deep_freeze if storage
    end

    # Instantiates a new storage instance from Occi::Infrastructure::Storage.
    # ID given in the occi.core.id attribute is optional and can be changed
    # inside this method. Final occi.core.id must be returned as a String.
    # If the requested instance cannot be created, an error describing the
    # problem must be raised, @see Backends::Errors.
    #
    # @example
    #    storage = Occi::Infrastructure::Storage.new
    #    storage_id = storage_create(storage)
    #        #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
    #
    # @param storage [Occi::Infrastructure::Storage] storage instance containing necessary attributes
    # @return [String] final identifier of the new storage instance
    def storage_create(storage)
      raise ArgumentError, '\'storage\' is a mandatory argument' if storage.blank?
      @backend_instance.storage_create(storage.deep_freeze)
    end

    # Deletes all storage instances, instances to be deleted must be filtered
    # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
    # If the requested instances cannot be deleted, an error describing the
    # problem must be raised, @see Backends::Errors.
    #
    # @example
    #    storage_delete_all #=> true
    #
    #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
    #    storage_delete_all(mixins)  #=> true
    #
    # @param mixins [Occi::Core::Mixins] a filter containing mixins
    # @return [true, false] result of the operation
    def storage_delete_all(mixins = nil)
      mixins = mixins.deep_freeze if mixins
      @backend_instance.storage_delete_all(mixins)
    end

    # Deletes a specific storage instance, instance to be deleted is
    # specified by an ID, this ID must match the occi.core.id attribute
    # of the deleted instance.
    # If the requested instance cannot be deleted, an error describing the
    # problem must be raised, @see Backends::Errors.
    #
    # @example
    #    storage_delete("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
    #
    # @param storage_id [String] an identifier of a storage instance to be deleted
    # @return [true, false] result of the operation
    def storage_delete(storage_id)
      raise ArgumentError, '\'storage_id\' is a mandatory argument' if storage_id.blank?
      @backend_instance.storage_delete(storage_id)
    end

    # Updates an existing storage instance, instance to be updated is specified
    # using the occi.core.id attribute of the instance passed as an argument.
    # If the requested instance cannot be updated, an error describing the
    # problem must be raised, @see Backends::Errors.
    #
    # @example
    #    storage = Occi::Infrastructure::Storage.new
    #    storage_update(storage) #=> true
    #
    # @param storage [Occi::Infrastructure::Storage] instance containing updated information
    # @return [true, false] result of the operation
    def storage_update(storage)
      raise ArgumentError, '\'storage\' is a mandatory argument' if storage.blank?
      @backend_instance.storage_update(storage.deep_freeze)
    end

    # Triggers an action on all existing storage instance, instances must be filtered
    # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance,
    # action is identified by the action.term attribute of the action instance passed as an argument.
    # If the requested action cannot be triggered, an error describing the
    # problem must be raised, @see Backends::Errors.
    #
    # @example
    #    action_instance = Occi::Core::ActionInstance.new
    #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
    #    storage_trigger_action_on_all(action_instance, mixin) #=> true
    #
    # @param action_instance [Occi::Core::ActionInstance] action to be triggered
    # @param mixins [Occi::Core::Mixins] a filter containing mixins
    # @return [true, false] result of the operation
    def storage_trigger_action_on_all(action_instance, mixins = nil)
      raise ArgumentError, '\'action_instance\' is a mandatory argument' if action_instance.blank?
      mixins = mixins.deep_freeze if mixins
      @backend_instance.storage_trigger_action_on_all(action_instance.deep_freeze, mixins)
    end

    # Triggers an action on an existing storage instance, the storage instance in question
    # is identified by a storage instance ID, action is identified by the action.term attribute
    # of the action instance passed as an argument.
    # If the requested action cannot be triggered, an error describing the
    # problem must be raised, @see Backends::Errors.
    #
    # @example
    #    action_instance = Occi::Core::ActionInstance.new
    #    storage_trigger_action("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf", action_instance)
    #      #=> true
    #
    # @param storage_id [String] storage instance identifier
    # @param action_instance [Occi::Core::ActionInstance] action to be triggered
    # @return [true, false] result of the operation
    def storage_trigger_action(storage_id, action_instance)
      raise ArgumentError, '\'storage_id\' is a mandatory argument' if storage_id.blank?
      raise ArgumentError, '\'action_instance\' is a mandatory argument' if action_instance.blank?
      @backend_instance.storage_trigger_action(storage_id, action_instance.deep_freeze)
    end

  end
end