class ResourceController < ApplicationController
  # GET /:resource/
  # (for legacy renderings and uri-list)
  def locations
    ids = default_backend_proxy.identifiers
    return if ids.blank?

    ids.map! { |id| absolute_url "/#{params[:resource]}/#{id}" }
    respond_with ids
  end

  # GET /:resource/
  # (for new renderings)
  def list
    resources = default_backend_proxy.list
    return if resources.blank? || resources.only_categories?

    respond_with resources
  end

  # GET /:resource/:id
  def show; end

  # POST /:resource/
  def create; end

  # POST /:resource/:id?action=ACTION
  def execute; end

  # POST /:resource/?action=ACTION
  def execute_all; end

  # PUT /:resource/:id
  def update
    render_error 501, 'Requested functionality is not implemented'
  end

  # POST /:resource/:id
  def partial_update; end

  # DELETE /:resource/:id
  def delete; end

  # DELETE /:resource/
  def delete_all; end

  protected

  def default_backend_proxy
    backend_proxy_for params[:resource]
  end
end
