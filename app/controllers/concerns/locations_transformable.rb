module LocationsTransformable
  # Converts given enumerable structure to an instance of `Occi::Core::Locations`
  # for later rendering or further processing.
  #
  # @param identifiers [Enumerable] list of identifiers
  # @param source [String] entity URL fragment or backend fragment name, defaults to `params.fetch(:entity)`
  # @param target [Occi::Core::Locations] instance to be populated, defaults to a new instance
  # @return [Occi::Core::Locations] converted structure
  def locations_from(identifiers, source = nil, target = nil)
    source ||= params[:entity]
    raise Errors::InternalError, 'Cannot create locations without valid source' if source.blank?
    target ||= Occi::Core::Locations.new

    identifiers.each { |id| target << absolute_url("/#{source}/#{id}") }
    target.valid!

    target
  end
end
