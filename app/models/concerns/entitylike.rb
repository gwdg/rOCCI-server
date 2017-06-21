module Entitylike
  extend ActiveSupport::Concern

  #
  #
  # @param identifier [String] UUID of the requested entity
  # @return [TrueClass] if entity exists
  # @return [FalseClass] if entity does not exist
  def exists?(identifier)
    identifiers.include?(identifier)
  end

  #
  #
  # @param filter [Set] collection of filtering rules
  # @return [Set] collection of entity identifiers matching the filter or all if filter is empty
  def identifiers(filter = Set.new)
    Set.new
  end

  #
  #
  # @param filter [Set] collection of filtering rules
  # @return [Set] collection of entities matching the filter or all if filter is empty
  def list(filter = Set.new)
    Set.new
  end

  #
  #
  # @param identifier [String] UUID of the requested entity
  # @return [Occi::Core::Entity] requested entity
  def instance(identifier)
    raise Errors::Backend::EntityNotFoundError, "Entity #{identifier} was not found"
  end

  #
  #
  # @param instance [Occi::Core::Entity] entity to be created
  # @return [String] identifier of the created entity
  def create(instance)
    instance['occi.core.id'] || instance.identify!
  end

  #
  #
  # @param identifier [String] UUID of the requested entity
  # @param fragments [Hash] stuff to update
  # @option fragments [Set] :mixins collection of mixins to update
  # @option fragments [Hash] :attributes collection of attributes to update
  # @return [Occi::Core::Entity] updated entity
  def partial_update(identifier, fragments)
    instance identifier
  end

  #
  #
  # @param identifier [String] UUID of the requested entity
  # @param new_instance [Occi::Core::Entity] full entity to replace the old one
  # @return [Occi::Core::Entity] updated entity
  def update(identifier, new_instance)
    instance identifier
  end

  #
  #
  # @param identifier [String] UUID of the requested entity
  # @param action_instance [Occi::Core::ActionInstance] action to be triggered
  # @return [String] identifier of the affected entity
  def trigger(identifier, action_instance)
    raise Errors::Backend::EntityNotFoundError, "Entity #{identifier} was not found"
  end

  #
  #
  # @param action_instance [Occi::Core::ActionInstance] action to be triggered
  # @param filter [Set] collection of filtering rules
  # @return [Set] collection of identifiers of affected entities
  def trigger_all(action_instance, filter = Set.new)
    Set.new
  end

  #
  #
  # @param identifier [String] UUID of the requested entity
  # @return [String] identifier of the affected entity
  def delete(identifier)
    instance identifier
  end

  #
  #
  # @param filter [Set] collection of filtering rules
  # @return [Set] collection of identifiers of affected entities
  def delete_all(filter = Set.new)
    Set.new
  end
end
