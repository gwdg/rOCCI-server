class LinkController < ApplicationController
  # GET /link/:link/
  # (for legacy renderings and uri-list)
  def locations; end

  # GET /link/:link/
  # (for new renderings)
  def list; end

  # GET /link/:link/:id
  def show; end

  # POST /link/:link/
  def create; end

  # POST /link/:link/:id?action=ACTION
  def execute
    render_error 501, 'Requested functionality is not implemented'
  end

  # POST /link/:link/?action=ACTION
  def execute_all
    render_error 501, 'Requested functionality is not implemented'
  end

  # PUT /link/:link/:id
  def update
    render_error 501, 'Requested functionality is not implemented'
  end

  # POST /link/:link/:id
  def partial_update
    render_error 501, 'Requested functionality is not implemented'
  end

  # DELETE /link/:link/:id
  def delete; end

  # DELETE /link/:link/
  delegate :delete_all, to: :default_backend_proxy

  protected

  def default_backend_proxy
    backend_proxy_for params[:link]
  end
end
