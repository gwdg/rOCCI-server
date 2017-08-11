module EntityRestrictable
  # Restrictions for entities
  RESTRICTIONS = {
    Occi::Infrastructure::Compute => [
      ->(entity) { one_mixin? entity, Occi::Infrastructure::Mixins::OsTpl.new },
      ->(entity) { one_mixin? entity, Occi::Infrastructure::Mixins::ResourceTpl.new },
      lambda do |entity|
        mxn = entity.select_mixins(Occi::Infrastructure::Mixins::ResourceTpl.new)
        return false if mxn.empty?
        defaults_unchanged? entity, mixin_attributes(mxn.first)
      end,
      ->(entity) { !many_mixins?(entity, Occi::InfrastructureExt::Mixins::AvailabilityZone.new) }
    ].freeze,
    Occi::InfrastructureExt::IPReservation => [
      ->(entity) { one_mixin? entity, Occi::InfrastructureExt::Mixins::Floatingippool.new }
    ].freeze,
    Occi::Infrastructure::Network => [
      # TODO: multi-cluster networks
      ->(entity) { !many_mixins?(entity, Occi::InfrastructureExt::Mixins::AvailabilityZone.new) }
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
    def no_mixin?(entity, mxn)
      entity.select_mixins(mxn).empty?
    end

    # :nodoc:
    def one_mixin?(entity, mxn)
      entity.select_mixins(mxn).one?
    end

    # :nodoc:
    def many_mixins?(entity, mxn)
      entity.select_mixins(mxn).many?
    end

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
      return false if rules.blank?
      rules.reduce(true) { |all, rule| all && rule['protocol'].present? && rule['type'].present? }
    end
  end
end
