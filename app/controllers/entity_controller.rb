class EntityController < ApplicationController
  include ParserAccessible

  # A way to separate Resources from Links
  LINK_PATH_PREFIX = '/link/'.freeze

  before_action :entitylike!
  before_action :instance_exists!, only: %i[show execute update partial_update delete]

  # GET (/link)/:entity/
  # (for legacy renderings and uri-list)
  def locations
    ids = default_backend_proxy.identifiers
    return if ids.blank?

    respond_with locations_from(ids)
  end

  # GET (/link)/:entity/
  # (for new renderings)
  def list
    entities = default_backend_proxy.list
    return if entities.blank? || entities.only_categories?

    respond_with entities
  end

  # GET (/link)/:entity/:id
  def show
    respond_with default_backend_proxy.instance(params[:id])
  end

  # POST (/link)/:entity/
  def create
    ids = resources_or_links.map { |r| default_backend_proxy.create(r) }
    return if ids.blank?

    respond_with locations_from(ids), status: :created
  end

  # POST (/link)/:entity/:id?action=ACTION
  def execute
    # TODO: parse AI and `trigger` on the backend
  end

  # POST (/link)/:entity/?action=ACTION
  def execute_all
    # TODO: parse AI and `trigger_all` on the backend
  end

  # PUT (/link)/:entity/:id
  def update
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST (/link)/:entity/:id
  def partial_update
    # TODO: parse M and `partial_update` on the backend
  end

  # DELETE (/link)/:entity/:id
  def delete
    default_backend_proxy.delete params[:id]
  end

  # DELETE (/link)/:entity/
  delegate :delete_all, to: :default_backend_proxy

  protected

  # Checks whether `:entity` specified in `params` is actually
  # a valid Entity-like term. If not, this will render and return
  # HTTP[404].
  def entitylike!
    return if backend_proxy.entitylike?(params[:entity])
    render_error :not_found, 'Requested entity type could not be found'
  end

  # Checks whether `:id` specified in `params` is actually an
  # existing instance. If not, this will render and return
  # HTTP[404].
  def instance_exists!
    return if default_backend_proxy.exists?(params[:id])
    render_error :not_found, 'Requested instance could not be found'
  end

  # Converts given enumerable structure to an instance of `Occi::Core::Locations`
  # for later rendering or further processing.
  #
  # @param identifiers [Enumerable] list of identifiers
  # @return [Occi::Core::Locations] converted structure
  def locations_from(identifiers)
    locations = Occi::Core::Locations.new

    identifiers.each do |id|
      relative_url = "#{linkish? ? LINK_PATH_PREFIX : '/'}#{params[:entity]}/#{id}"
      locations << absolute_url(relative_url)
    end
    locations.valid!

    locations
  end

  # Checks whether the current request should assume Link-like entity subtypes.
  #
  # @return [TrueClass] if request path suggests certain linkiness
  # @return [FalseClass] if NOT
  def linkish?
    request.original_fullpath.start_with?(LINK_PATH_PREFIX)
  end

  # Attempts to parse and return the correct instance collection for this request type.
  #
  # @return [Set] collection of instances
  def resources_or_links
    linkish? ? request_links : request_resources
  end

  # Returns default backend instance for the given controller.
  #
  # @return [Entitylike, Extenderlike] subtype instance
  def default_backend_proxy
    backend_proxy_for params[:entity]
  end
end
