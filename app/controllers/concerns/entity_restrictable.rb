module EntityRestrictable
  # Restrictions for entities
  RESTRICTIONS = {
    Occi::Infrastructure::Compute => [
      ->(entity) { [entity.os_tpl].one? },
      ->(entity) { [entity.resource_tpl].one? },
      ->(entity) { defaults_unchanged?(entity, mixin_attributes(entity.resource_tpl)) },
      ->(entity) { !entity.availability_zones.many? }
    ].freeze,
    Occi::InfrastructureExt::IPReservation => [
      ->(entity) { [entity.floatingippool].one? }
    ].freeze,
    Occi::Infrastructure::Network => [
      # TODO: multi-cluster networks
      ->(entity) { !entity.availability_zones.many? }
    ].freeze,
    Occi::InfrastructureExt::SecurityGroup => [
      ->(entity) { entity['occi.securitygroup.rules'].present? },
      ->(entity) { valid_sg_rules?(entity['occi.securitygroup.rules']) }
    ].freeze
  }.freeze

  # @param entity [Occi::Core::Entity] entity to restrict
  def restrict!(entity)
    return unless RESTRICTIONS.key?(entity.class)
    return if RESTRICTIONS[entity.class].reduce(true) { |all, restr| all && restr.call(entity) }
    # TODO: detailed error messages
    raise Errors::ValidationError, 'Submitted entity is not compliant with server restrictions'
  end

  class << self
    # :nodoc:
    def defaults_unchanged?(entity, attributes)
      attributes.reduce(true) { |all, attrib| all && default_unchanged?(entity.attributes[attrib]) }
    end

    # :nodoc:
    def default_unchanged?(attribute)
      attribute.value == attribute.attribute_definition.default
    end

    # :nodoc:
    def mixin_attributes(mixin)
      mixin.attributes.keys
    end

    # :nodoc:
    def valid_sg_rules?(rules)
      rules.reduce(true) { |all, rule| all && rule['protocol'].present? && rule['type'].present? }
    end
  end
end
