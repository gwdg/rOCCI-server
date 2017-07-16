module LocationsTransformable
  extend ActiveSupport::Concern

  # A way to separate Resources from Links
  LINK_PATH_PREFIX = '/link/'.freeze

  included do
    delegate :link_path_prefix, to: :class
  end

  class_methods do
    # @see `LINK_PATH_PREFIX`
    def link_path_prefix
      LINK_PATH_PREFIX
    end
  end

  # Converts given enumerable structure to an instance of `Occi::Core::Locations`
  # for later rendering or further processing.
  #
  # @param identifiers [Enumerable] list of identifiers
  # @param source [String] entity URL fragment or backend fragment name, defaults to `params.fetch(:entity)`
  # @param target [Occi::Core::Locations] instance to be populated, defaults to a new instance
  # @return [Occi::Core::Locations] converted structure
  def locations_from(identifiers, source = nil, target = nil)
    source ||= params[:entity]
    raise 'Cannot create locations without valid source' if source.blank?
    target ||= Occi::Core::Locations.new

    identifiers.each do |id|
      relative_url = "#{linkish?(source) ? LINK_PATH_PREFIX : '/'}#{source}/#{id}"
      target << absolute_url(relative_url)
    end
    target.valid!

    target
  end

  # Checks whether the given entity belongs to Link-like entity subtypes.
  #
  # @param entity [String] entity name, from URL (i.e., term-like)
  # @return [TrueClass] if certain linkiness is suggested
  # @return [FalseClass] if NOT
  def linkish?(entity)
    BackendProxy.linklike?(entity.to_sym)
  end

  # @see `linkish?`
  def resourceish?(entity)
    BackendProxy.resourcelike?(entity.to_sym)
  end
end
