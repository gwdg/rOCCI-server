class ResourceController < ApplicationController
  include ParserAccessible

  before_action :resource_exists!, only: %i[show execute update partial_update delete]

  # GET /:resource/
  # (for legacy renderings and uri-list)
  def locations
    ids = default_backend_proxy.identifiers
    return if ids.blank?

    respond_with locations_from(ids)
  end

  # GET /:resource/
  # (for new renderings)
  def list
    resources = default_backend_proxy.list
    return if resources.blank? || resources.only_categories?

    respond_with resources
  end

  # GET /:resource/:id
  def show
    respond_with default_backend_proxy.instance(params[:id])
  end

  # POST /:resource/
  def create
    # TODO: parse R and `create` and the backend
  end

  # POST /:resource/:id?action=ACTION
  def execute
    # TODO: parse AI and `trigger` on the backend
  end

  # POST /:resource/?action=ACTION
  def execute_all
    # TODO: parse AI and `trigger_all` on the backend
  end

  # PUT /:resource/:id
  def update
    render_error 501, 'Requested functionality is not implemented'
  end

  # POST /:resource/:id
  def partial_update
    # TODO: parse M and `partial_update` on the backend
  end

  # DELETE /:resource/:id
  def delete
    default_backend_proxy.delete params[:id]
  end

  # DELETE /:resource/
  delegate :delete_all, to: :default_backend_proxy

  protected

  def locations_from(identifiers)
    locations = Occi::Core::Locations.new

    identifiers.each { |id| locations << absolute_url("/#{params[:resource]}/#{id}") }
    locations.valid!

    locations
  end

  def default_backend_proxy
    backend_proxy_for params[:resource]
  end

  def resource_exists!
    return if default_backend_proxy.exists?(params[:id])
    render_error 404, 'Requested resource could not be found'
  end
end
