class EntityController < ApplicationController
  include ParserAccessible
  include LocationsTransformable
  include EntityRestrictable

  before_action :entitylike!
  before_action :validate_provided_format!, only: %i[create execute execute_all update partial_update]
  before_action :instance_exists!, only: %i[show execute update partial_update delete]

  # GET /:entity/
  # (for legacy renderings and uri-list)
  def locations
    ids = default_backend_proxy.identifiers
    return if ids.blank?

    respond_with locations_from(ids)
  end

  # GET /:entity/
  # (for new renderings)
  def list
    coll = empty_collection

    coll.entities = default_backend_proxy.list.entities
    return if coll.only_categories?
    coll.valid!

    respond_with coll
  end

  # GET /:entity/:id
  def show
    entity = default_backend_proxy.instance(params[:id])
    entity.valid!

    respond_with entity
  end

  # POST /:entity/
  def create
    coll = resources_or_links.select { |rol| default_backend_proxy.serves?(rol.class) }
    if coll.empty?
      render_error :bad_request, 'Given instance(s) not supported in this collection'
      return
    end

    ids = coll.map do |entity|
      restrict! entity
      default_backend_proxy.create entity
    end
    respond_with locations_from(ids), status: :created
  end

  # POST /:entity/:id?action=ACTION
  def execute
    coll = request_action_instances
    unless coll.one?
      render_error :bad_request, 'Single action instance must be given'
      return
    end

    ret_coll = default_backend_proxy.trigger(params[:id], coll.first)
    respond_with ret_coll unless ret_coll.empty?
  end

  # POST /:entity/?action=ACTION
  def execute_all
    coll = request_action_instances
    unless coll.one?
      render_error :bad_request, 'Single action instance must be given'
      return
    end

    ret_coll = default_backend_proxy.trigger_all(coll.first)
    respond_with ret_coll unless ret_coll.empty?
  end

  # PUT /:entity/:id
  def update
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /:entity/:id
  def partial_update
    coll = request_mixins
    if coll.empty?
      render_error :bad_request, 'No mixins given for updating the instance'
      return
    end

    entity = default_backend_proxy.partial_update(params[:id], mixins: coll)
    entity.valid!

    respond_with entity
  end

  # DELETE /:entity/:id
  def delete
    default_backend_proxy.delete params[:id]
  end

  # DELETE /:entity/
  delegate :delete_all, to: :default_backend_proxy

  protected

  # Checks whether `:entity` specified in `params` is actually
  # a valid Entity-like term. If not, this will render and return
  # HTTP[404].
  def entitylike!
    return if BackendProxy.entitylike?(params[:entity].to_sym)
    render_error :not_found, 'Requested entity type could not be found'
  end

  # Checks whether `:id` specified in `params` is actually an
  # existing instance. If not, this will render and return
  # HTTP[404].
  def instance_exists!
    return if default_backend_proxy.exists?(params[:id])
    render_error :not_found, 'Requested instance could not be found'
  end

  # Attempts to parse and return the correct instance collection for this request type.
  #
  # @return [Set] collection of instances
  def resources_or_links
    linkish?(params[:entity]) ? request_links : request_resources
  end

  # Returns default backend instance for the given controller.
  #
  # @return [Entitylike, Extenderlike] subtype instance
  def default_backend_proxy
    backend_proxy_for params[:entity]
  end

  # Checks whether the given entity belongs to Link-like entity subtypes.
  #
  # @param entity [String] entity name, from URL (i.e., term-like)
  # @return [TrueClass] if certain linkiness is suggested
  # @return [FalseClass] if NOT
  def linkish?(entity)
    BackendProxy.linklike?(entity.to_sym)
  end
end
