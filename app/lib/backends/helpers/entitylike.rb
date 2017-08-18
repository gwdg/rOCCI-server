module Backends
  module Helpers
    module Entitylike
      extend ActiveSupport::Concern

      included do
        delegate :serves?, to: :class
        delegate :server_model, to: :backend_proxy
        delegate :instance_builder, to: :server_model
        delegate :find_by_identifier!, to: :server_model
      end

      class_methods do
        # Checks whether the given class is served by this particular
        # backend part.
        #
        # @example
        #    compute.serves?(Occi::Infrastructure::Compute) # => true
        #    compute.serves?(Occi::Infrastructure::Network) # => false
        #
        # @param klass [Class] class to check
        # @return [TrueClass] if serves
        # @return [FalseClass] if does not serve
        def serves?(klass)
          klass.ancestors.include?(served_class)
        end

        # Returns class served by this backend part. This method should be overriden
        # by each implementing part.
        #
        # @return [Class] served class
        def served_class
          Occi::Core::Entity
        end
      end

      # Checks whether there is an instance with the given identifier.
      #
      # @param identifier [String] UUID of the requested entity
      # @return [TrueClass] if entity exists
      # @return [FalseClass] if entity does not exist
      def exists?(identifier)
        identifiers.include?(identifier)
      end

      # Provides a set of instance identifiers. In most cases, this is a collection
      # of `occi.core.id`s from all instances.
      #
      # @param filter [Set] collection of filtering rules
      # @return [Set] collection of entity identifiers matching the filter or all if filter is empty
      def identifiers(filter = Set.new)
        list(filter).entities.map { |ent| ent['occi.core.id'] }
      end

      # Provides a collection of complete entity instances.
      #
      # @param filter [Set] collection of filtering rules
      # @return [Occi::Core::Collection] collection of entities matching the filter or all if filter is empty
      def list(_filter = Set.new)
        raise Errors::Backend::NotImplementedError, 'Requested functionality is not implemented'
      end

      # Retrieves a specific entity instance. An `Errors::Backend::EntityNotFoundError` error will be raised
      # if no such instance is available.
      #
      # @param identifier [String] UUID of the requested entity
      # @raise [Errors::Backend::EntityNotFoundError] if instance does not exist
      # @return [Occi::Core::Entity] requested entity
      def instance(_identifier)
        raise Errors::Backend::NotImplementedError, 'Requested functionality is not implemented'
      end

      # Creates a backend-specific instance from the provided entity instance. On success, identifier
      # of the new instance is returned. An appropriate error should be raised in case of failure.
      #
      # @param instance [Occi::Core::Entity] entity to be created
      # @return [String] identifier of the created entity
      def create(_instance)
        raise Errors::Backend::NotImplementedError, 'Requested functionality is not implemented'
      end

      # Performs partial update on instance specified by `identifier`. Instance is updated selectively
      # from the content of `fragments`. This usually includes updating mixins or attributes.
      # An appropriate error should be raised in case of failure.
      #
      # @param identifier [String] UUID of the requested entity
      # @param fragments [Hash] stuff to update
      # @option fragments [Set] :mixins collection of mixins to update
      # @option fragments [Hash] :attributes collection of attributes to update
      # @return [Occi::Core::Entity] updated entity
      def partial_update(_identifier, _fragments)
        raise Errors::Backend::NotImplementedError, 'Requested functionality is not implemented'
      end

      # Performs a full update on the instance specified by `identifier`. Instance is replaced
      # by a new instance specified in `new_instance`. An appropriate error should be raised in case of failure.
      #
      # @param identifier [String] UUID of the requested entity
      # @param new_instance [Occi::Core::Entity] full entity to replace the old one
      # @return [Occi::Core::Entity] updated entity
      def update(_identifier, _new_instance)
        raise Errors::Backend::NotImplementedError, 'Requested functionality is not implemented'
      end

      # Executes an action specified by `action_instance` on entity specified by `identifier`.
      # An appropriate error should be raised in case of failure.
      #
      # @param identifier [String] UUID of the requested entity
      # @param action_instance [Occi::Core::ActionInstance] action to be triggered
      # @return [Occi::Core::Collection] result(s) of the action, in a collection
      def trigger(_identifier, _action_instance)
        raise Errors::Backend::NotImplementedError, 'Requested functionality is not implemented'
      end

      # Bulk-executes an action specified by `action_instance` on all instances.
      # An appropriate error should be raised in case of failure.
      #
      # @param action_instance [Occi::Core::ActionInstance] action to be triggered
      # @param filter [Set] collection of filtering rules
      # @return [Occi::Core::Collection] result(s) of the action, in a collection
      def trigger_all(action_instance, filter = Set.new)
        collection = Occi::Core::Collection.new
        identifiers(filter).each { |id| collection.categories.merge trigger(id, action_instance).categories }
        collection
      end

      # Destroys an instance specified by `identifier`. An appropriate error should be raised in case of failure.
      #
      # @param identifier [String] UUID of the requested entity
      # @return [String] identifier of the affected entity
      def delete(_identifier)
        raise Errors::Backend::NotImplementedError, 'Requested functionality is not implemented'
      end

      # Bulk-destroys all instances. An appropriate error should be raised in case of failure.
      #
      # @param filter [Set] collection of filtering rules
      # @return [Set] collection of identifiers of affected entities
      def delete_all(filter = Set.new)
        Set.new(identifiers(filter).map { |id| delete(id) })
      end
    end
  end
end
